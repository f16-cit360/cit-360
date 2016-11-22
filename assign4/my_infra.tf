variable "vpc" {
  default = ""
}

variable "vpc_cidr" {
  default = "172.31.0.0/16"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${var.vpc}"

  tags = {
    Name = "default_ig"
  }
}

resource "aws_route_table" "public_routing_table" {
  vpc_id = "vpc-d1d5c4b5"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "public_routing_table"
  }
}

resource "aws_subnet" "public_subnet_a" {
    vpc_id = "vpc-d1d5c4b5"
    cidr_block = "172.31.1.0/24"
    availability_zone = "us-west-2a"

    tags {
        Name = "public_a"
    }
}

resource "aws_route_table_association" "public_subnet_a_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_security_group" "windows" {
  name = "windows"
  description = "Allow windows traffic"

  ingress {
      from_port = 53
      to_port = 53
      protocol = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 53
      to_port = 53
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 88
      to_port = 88
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 88
      to_port = 88
      protocol = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 135
      to_port = 135
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 137
      to_port = 137
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 137
      to_port = 137
      protocol = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 139
      to_port = 139
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 139
      to_port = 139
      protocol = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 389
      to_port = 389
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 389
      to_port = 389
      protocol = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 389
      to_port = 389
      protocol = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 445
      to_port = 445
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 445
      to_port = 445
      protocol = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 464
      to_port = 464
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 464
      to_port = 464
      protocol = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 636
      to_port = 636
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 3268
      to_port = 3268
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 3269
      to_port = 3269
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 3389
      to_port = 3389
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 1024
      to_port = 65535
      protocol = "tcp"
      cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
      from_port = 1024
      to_port = 65535
      protocol = "udp"
      cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
      from_port = 8
      to_port = 0
      protocol = "icmp"
      cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "server" {
    ami = "ami-b871aad8"
    associate_public_ip_address = true
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    instance_type = "c4.large"
    tags {
        Name = "server"
    }
    key_name = "cit360"
    vpc_security_group_ids = ["${aws_security_group.windows.id}"]
}

#
# Uncomment this when you are ready to connect a client to the domain
#
#resource "aws_instance" "client" {
#    ami = "ami-b871aad8"
#    associate_public_ip_address = true
#    subnet_id = "${aws_subnet.public_subnet_a.id}"
#    instance_type = "c4.large"
#    tags {
#        Name = "client"
#    }
#    key_name = "cit360"
#    vpc_security_group_ids = ["${aws_security_group.windows.id}"]
#}
