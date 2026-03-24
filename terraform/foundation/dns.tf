# =============================================================================
# dns.tf
# Route53 DNS for Conjur Enterprise.
# Record: conjur.<your-domain>  →  Conjur EC2 public IP
# =============================================================================

# Look up the existing hosted zone — we don't create it, just use it
data "aws_route53_zone" "main" {
  name         = var.route53_zone_name
  private_zone = false
}

# A record for Conjur — created here as a placeholder, the actual EC2 resource
# (and its IP) is created in the Conjur EC2 module (Phase 0b).
# We use a separate resource so DNS is visible from foundation outputs.
resource "aws_route53_record" "conjur" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.conjur_subdomain}.${var.route53_zone_name}"
  type    = "A"
  ttl     = 60  # Low TTL during demo — allows quick updates if IP changes

  # This references the Conjur EC2 public IP. If you haven't created the
  # EC2 instance yet, comment this out and run terraform apply in two passes:
  #   Pass 1: foundation networking (comment out this record)
  #   Pass 2: uncomment after Conjur EC2 is provisioned
  records = [aws_eip.conjur.public_ip]
}

# Dedicated EIP for Conjur — decoupled from the instance so the DNS record
# stays stable even if you stop/start or replace the Conjur EC2
resource "aws_eip" "conjur" {
  domain = "vpc"
  tags   = { Name = "${var.project}-conjur-eip" }

  depends_on = [aws_internet_gateway.main]
}
