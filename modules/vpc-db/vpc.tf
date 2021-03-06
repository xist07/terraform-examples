provider "aws" {
  region = var.region_name
}

variable "region_name" {
  description = "region name"
}


variable "vpc_cidr" {
  description = "The vpc CIDR"
}


resource "aws_vpc" "ey_db_vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eyassir-database-terraform"
  }
}

resource "aws_vpc_dhcp_options" "dns_options" {
  domain_name_servers = ["8.8.8.8", "8.8.4.4"]
}


resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.ey_db_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dns_options.id
}

resource "aws_security_group" "ey_db_vpc_default_sg" {
  name        = "ey_db_vpc_default_sg"
  description = "Allow ALL inbound traffic"
  vpc_id      = aws_vpc.ey_db_vpc.id

  ingress {
    description = "Allow all Traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ey-vpc-database-sg"
  }
}

resource "aws_network_acl" "ey_default_acl" {
  vpc_id = aws_vpc.ey_db_vpc.id

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  tags = {
    Name = "ey_database_acl"
  }
}

resource "aws_default_route_table" "r" {
  default_route_table_id = aws_vpc.ey_db_vpc.default_route_table_id

  tags = {
    Name = "ey-database-private-route"
  }
}

output "custom_db_vpc" {
  value = aws_vpc.ey_db_vpc
}

output "custom_database_main_route" {
  value = aws_default_route_table.r
}
