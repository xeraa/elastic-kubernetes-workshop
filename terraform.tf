provider "aws" {
    # Credentials are defined in the environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
    region = var.region
}


# Create the SSH key pair
resource "aws_lightsail_key_pair" "aws_key_pair" {
  name       = "aws_key_pair"
  public_key = file("~/.ssh/id_rsa.pub")
}


# Create the instance and its DNS entries
resource "aws_lightsail_instance" "instance" {
  name              = "instance"
  availability_zone = "${var.region}a"
  blueprint_id      = var.operating_system
  bundle_id         = var.size
  key_pair_name     = "aws_key_pair"
  depends_on        = [aws_lightsail_key_pair.aws_key_pair]
}
resource "aws_lightsail_instance_public_ports" "instance" {
  instance_name = aws_lightsail_instance.instance.name
  # SSH (defaults are overwritten so this must be specified)
  port_info {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
  }
  # So Let's Encrypt can generate its certificate
  port_info {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
  }
  # Kibana
  port_info {
    protocol  = "tcp"
    from_port = 5601
    to_port   = 5601
  }
  # Alternative HTTP
  port_info {
    protocol  = "tcp"
    from_port = 8080
    to_port   = 8080
  }
}
resource "aws_route53_record" "apex" {
  zone_id = var.zone_id
  name    = var.domain
  type    = "A"
  ttl     = "60"
  records = [aws_lightsail_instance.instance.public_ip_address]
}
