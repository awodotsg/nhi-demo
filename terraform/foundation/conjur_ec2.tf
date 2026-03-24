# =============================================================================
# conjur_ec2.tf
# EC2 instance that will run Conjur Enterprise on Docker
# =============================================================================

# Latest Amazon Linux 2023 AMI — stable, has Docker in its repo
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "conjur" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.conjur_instance_type
  key_name               = aws_key_pair.main.key_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.conjur.id]
  iam_instance_profile   = aws_iam_instance_profile.conjur.name

  # Increase root volume — Conjur images are large (~2GB compressed)
  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # User data installs Docker and docker-compose, then waits for Ansible
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euo pipefail

    # Update and install Docker
    dnf update -y
    dnf install -y docker git

    # Start and enable Docker
    systemctl enable docker
    systemctl start docker

    # Add ec2-user to docker group
    usermod -aG docker ec2-user

    # Install Docker Compose v2 plugin via curl
    COMPOSE_VERSION="v2.27.1"
    mkdir -p /usr/local/lib/docker/cli-plugins

    curl -SL --fail --retry 3 --retry-delay 5 \
      "https://github.com/docker/compose/releases/download/$${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
      -o /usr/local/lib/docker/cli-plugins/docker-compose || {
        echo "FATAL: docker-compose download failed" >> /var/log/nhi-demo-setup.log
        exit 1
      }

    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    # Verify binary is valid
    file /usr/local/lib/docker/cli-plugins/docker-compose | grep -q "ELF 64-bit" || {
      echo "FATAL: docker-compose binary invalid" >> /var/log/nhi-demo-setup.log
      exit 1
    }

    # Verify plugin registers correctly
    docker compose version >> /var/log/nhi-demo-setup.log 2>&1 || {
      echo "FATAL: docker compose version check failed" >> /var/log/nhi-demo-setup.log
      exit 1
    }

    # Signal that user data is complete
    touch /tmp/userdata-complete
    echo "Docker setup complete. Ready for Ansible." >> /var/log/nhi-demo-setup.log
    EOF
  )

  tags = { Name = "${var.project}-conjur" }

  # Wait for user data to finish before Ansible runs
  # (Ansible checks for /tmp/userdata-complete)
}

# Associate the dedicated Conjur EIP (from dns.tf) with this instance
resource "aws_eip_association" "conjur" {
  instance_id   = aws_instance.conjur.id
  allocation_id = aws_eip.conjur.id
}
