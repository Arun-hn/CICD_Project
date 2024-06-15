locals {
  inbound_ports = [22, 25, 80, 443, 465, 6443, 8080, 8081, 9000, 27071]
  port_ranges   = [{ from = 3000, to = 10000 }, { from = 30000, to = 32767 }]
}

# Security Groups
resource "aws_security_group" "open_ports" {
  name        = "open_ports_sg"
  description = "Security group with open ports"
  vpc_id      = aws_vpc.main.id


  dynamic "ingress" {
    for_each = local.inbound_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Handle port ranges
  dynamic "ingress" {
    for_each = local.port_ranges
    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
