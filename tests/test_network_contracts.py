"""Guardrails for the AWS networking contract.

These assertions catch accidental security regressions before AWS deployment.
They are static checks, not a substitute for a live two-account acceptance test.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


class NetworkContractTests(unittest.TestCase):
    def test_vpn_does_not_inherit_default_vpc_security_group(self):
        text = (ROOT / "modules/client-vpn/main.tf").read_text()
        self.assertRegex(text, r'(?m)^resource "aws_security_group" "client_vpn"')
        endpoint = text.split('resource "aws_ec2_client_vpn_endpoint" "this" {', 1)[1]
        self.assertIn('vpc_id                 = var.vpc_id', endpoint)
        self.assertIn('security_group_ids     = [aws_security_group.client_vpn.id]', endpoint)

    def test_vpn_egress_targets_published_endpoint(self):
        client = (ROOT / "modules/client-vpn/main.tf").read_text()
        consumer = (ROOT / "envs/dev/main.tf").read_text()
        self.assertIn('toset(var.allowed_application_security_group_ids)', client)
        self.assertIn('security_groups = [egress.value]', client)
        self.assertIn('module.privatelink_consumer.endpoint_security_group_id', consumer)
        self.assertNotRegex(client, r'(?m)^\s*cidr_blocks\s*=\s*\["0\.0\.0\.0/0"\]')

    def test_interface_endpoint_alias_does_not_fake_health(self):
        text = (ROOT / "modules/privatelink-consumer/main.tf").read_text()
        self.assertIn("evaluate_target_health = false", text)


if __name__ == "__main__":
    unittest.main()
