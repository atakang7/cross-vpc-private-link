#!/usr/bin/env python3
"""Offline integration tests: mock AWS control plane and local TCP data plane.

This deliberately does not claim to implement real AWS PrivateLink or Client VPN.
No AWS credentials, Docker, cloud resources, or third-party libraries required.
"""
import json
import os
from pathlib import Path
import re
import select
import shutil
import socket
import socketserver
import subprocess
import sys
import tempfile
import threading
import time
import unittest
import urllib.request

ROOT = Path(__file__).resolve().parents[1]

FAKE_AWS = r'''#!/usr/bin/env python3
import os, sys
args = sys.argv[1:]
profile = args[args.index('--profile') + 1] if '--profile' in args else os.environ.get('AWS_PROFILE', '')
with open(os.environ['DEMO_AUDIT'], 'a') as file:
    file.write(f'aws {args[0]} {args[1]} profile={profile}\n')
if args[:2] == ['sts', 'get-caller-identity']:
    assert profile in ('dev', 'prod'), profile
    print('123456789012' if profile == 'dev' or os.environ.get('DEMO_SAME_ACCOUNT') else '210987654321')
elif args[:2] == ['acm', 'import-certificate']:
    assert profile == 'dev', profile
    assert '--private-key' in args and '--certificate' in args
    kind = 'ca' if 'ca.crt' in args[args.index('--certificate') + 1] else 'server'
    print('arn:aws:acm:eu-central-1:123456789012:certificate/demo-' + kind)
elif args[:2] == ['ec2', 'export-client-vpn-client-configuration']:
    assert profile == 'dev', profile
    assert args[args.index('--client-vpn-endpoint-id') + 1] == 'cvpn-endpoint-demo'
    print('client\ndev tun\nproto udp\nremote cvpn.example.invalid 443')
else:
    sys.exit(f'Unexpected AWS CLI call: {args}')
'''

FAKE_TOFU = r'''#!/usr/bin/env python3
import os, sys
args = sys.argv[1:]
chdir = next((arg.split('=', 1)[1] for arg in args if arg.startswith('-chdir=')), '')
stack = chdir.rsplit('/', 1)[-1]
verb = next((arg for arg in args if arg in ('init', 'apply', 'output', 'destroy')), '')
profile = os.environ.get('AWS_PROFILE', '')
with open(os.environ['DEMO_AUDIT'], 'a') as file:
    file.write(f'tofu {verb} stack={stack} profile={profile} args={" ".join(args)}\n')
assert profile == stack, f'wrong account: {profile=} {stack=}'
assert verb, args
if verb == 'init':
    assert '-backend-config=backend.hcl' in args
elif verb in ('apply', 'destroy'):
    if stack == 'prod':
        assert any('dev_account_root_arn=arn:aws:iam::123456789012:root' in arg for arg in args), args
    else:
        for name in ('vpn_server_cert_arn', 'vpn_root_ca_arn', 'privatelink_service_name'):
            assert any(arg.startswith(name + '=') for arg in args), (name, args)
        assert any('privatelink_service_name=com.amazonaws.vpce.eu-central-1.vpce-svc-demo' in arg for arg in args)
    if verb == 'apply':
        assert '-auto-approve' not in args, 'The deployment must require approval.'
elif verb == 'output':
    values = {
        'hello_world_service_name': 'com.amazonaws.vpce.eu-central-1.vpce-svc-demo',
        'vpn_endpoint': 'cvpn-endpoint-demo',
        'vpn_dns': 'cvpn-endpoint-demo.clientvpn.eu-central-1.amazonaws.com',
    }
    assert args[-1] in values, args
    print(values[args[-1]])
'''


def launch(script, repo, env):
    args = ['bash', script]
    if os.geteuid() == 0:
        args = ['runuser', '-u', 'nobody', '--', *args]
    return subprocess.run(args, cwd=repo, env=env, input='yes\nyes\n',
                          text=True, capture_output=True, timeout=90)


class TCPProxy(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

    def __init__(self, upstream):
        self.upstream = upstream
        super().__init__(('127.0.0.1', 0), ProxyHandler)


class ProxyHandler(socketserver.BaseRequestHandler):
    def handle(self):
        try:
            with socket.create_connection(self.server.upstream, timeout=3) as remote:
                self.request.settimeout(3)
                remote.settimeout(3)
                peers = (self.request, remote)
                while True:
                    readable, _, _ = select.select(peers, [], [], 3)
                    if not readable:
                        return
                    for peer in readable:
                        data = peer.recv(65536)
                        if not data:
                            return
                        (remote if peer is self.request else self.request).sendall(data)
        except (TimeoutError, OSError):
            pass


def free_port():
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        return sock.getsockname()[1]


class SandboxDemo(unittest.TestCase):
    def test_control_plane_mock_accounts_and_destroy_order(self):
        with tempfile.TemporaryDirectory() as directory:
            work = Path(directory)
            repo = work / 'repo'
            shutil.copytree(ROOT, repo,
                            ignore=shutil.ignore_patterns('.git', '.terraform', '__pycache__', 'certs'))
            for stack in ('dev', 'prod'):
                (repo / 'envs' / stack / 'backend.hcl').write_text('bucket = "test-only"\n')
            mockbin = work / 'mockbin'
            mockbin.mkdir()
            for name, source in (('aws', FAKE_AWS), ('tofu', FAKE_TOFU)):
                path = mockbin / name
                path.write_text(source)
                path.chmod(0o755)
            audit = work / 'audit.log'
            audit.touch()
            env = dict(os.environ, PATH=str(mockbin) + os.pathsep + os.environ['PATH'],
                       DEMO_AUDIT=str(audit), DEV_PROFILE='dev', PROD_PROFILE='prod')
            if os.geteuid() == 0:
                for node in [work, *work.rglob('*')]:
                    os.chown(node, 65534, 65534)
            run = launch('first-run.sh', repo, env)
            self.assertEqual(run.returncode, 0, run.stdout + '\n' + run.stderr)
            events = audit.read_text().splitlines()
            provider = next(i for i, e in enumerate(events) if 'tofu apply stack=prod profile=prod' in e)
            consumer = next(i for i, e in enumerate(events) if 'tofu apply stack=dev profile=dev' in e)
            self.assertLess(provider, consumer)
            self.assertTrue((repo / 'dev.ovpn').exists())
            self.assertEqual((repo / 'dev.ovpn').stat().st_mode & 0o777, 0o600)
            self.assertTrue((repo / 'scripts/certs/client.crt').exists())
            self.assertTrue((repo / 'scripts/certs/client.key').exists())
            # Teardown is explicitly non-interactive in the sandbox.
            args = ['bash', 'scripts/70_destroy_all.sh', '--yes']
            if os.geteuid() == 0:
                args = ['runuser', '-u', 'nobody', '--', *args]
            clean = subprocess.run(args, cwd=repo, env=env, text=True,
                                   capture_output=True, timeout=30)
            self.assertEqual(clean.returncode, 0, clean.stdout + '\n' + clean.stderr)
            events = audit.read_text().splitlines()
            self.assertLess(next(i for i, e in enumerate(events) if 'tofu destroy stack=dev' in e),
                            next(i for i, e in enumerate(events) if 'tofu destroy stack=prod' in e))
            # A same-account misconfiguration must stop before any deploy.
            audit.write_text('')
            invalid = launch('first-run.sh', repo, {**env, 'DEMO_SAME_ACCOUNT': '1'})
            self.assertNotEqual(invalid.returncode, 0)
            self.assertFalse(any('tofu apply' in e for e in audit.read_text().splitlines()))

    def test_live_demo_backend_through_three_local_tcp_hops(self):
        template = (ROOT / 'modules/privatelink-provider/bootstrap.sh.tftpl').read_text()
        match = re.search(r"cat > /opt/hello_world\.py <<'PY'\n(.*?)\nPY", template, re.S)
        self.assertIsNotNone(match, 'Python backend missing from EC2 bootstrap template')
        backend_port = free_port()
        source = match.group(1).replace('$' + '{port}', str(backend_port))
        with subprocess.Popen([sys.executable, '-u', '-c', source],
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE) as proc:
            for _ in range(60):
                try:
                    with socket.create_connection(('127.0.0.1', backend_port), timeout=.1):
                        break
                except OSError:
                    time.sleep(.05)
            else:
                self.fail('Backend failed to start: ' + proc.stderr.read().decode(errors='replace'))
            # A real HTTP request crosses local TCP proxies representing:
            # VPN ingress -> interface endpoint -> provider NLB -> demo EC2.
            with TCPProxy(('127.0.0.1', backend_port)) as nlb:
                with TCPProxy(nlb.server_address) as endpoint:
                    with TCPProxy(endpoint.server_address) as vpn:
                        threads = []
                        for server in (nlb, endpoint, vpn):
                            thread = threading.Thread(target=server.serve_forever, daemon=True)
                            thread.start()
                            threads.append(thread)
                        try:
                            request = urllib.request.Request(
                                f'http://127.0.0.1:{vpn.server_address[1]}/',
                                headers={'Host': 'hello.internal.company'})
                            with urllib.request.urlopen(request, timeout=5) as response:
                                self.assertEqual(response.status, 200)
                                payload = json.load(response)
                            self.assertEqual(payload['message'], 'Hello from provider')
                            self.assertIn('ts', payload)
                        finally:
                            for server in (vpn, endpoint, nlb):
                                server.shutdown()
                            for thread in threads:
                                thread.join(timeout=3)
            proc.terminate()
            proc.wait(timeout=5)


if __name__ == '__main__':
    unittest.main(verbosity=2)
