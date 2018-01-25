# Add your VPC ID to default below
variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = ""
}

variable "db_pass" {}

provider "aws" {
  region = "us-west-2"
  profile = ""
}

# Public subnet resources
resource "aws_internet_gateway" "gw" {
  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "default_ig"
  }
}

resource "aws_route_table" "public_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "public_routing_table"
  }
}

resource "aws_subnet" "public_subnet_a" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.0.0/24"
    availability_zone = "us-west-2a"

    tags {
        Name = "public_a"
    }
}

resource "aws_route_table_association" "public_a_rt" {
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_subnet" "public_subnet_b" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.1.0/24"
    availability_zone = "us-west-2b"

    tags {
        Name = "public_b"
    }
}

resource "aws_route_table_association" "public_b_rt" {
  subnet_id = "${aws_subnet.public_subnet_b.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_subnet" "public_subnet_c" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.2.0/24"
    availability_zone = "us-west-2c"

    tags {
        Name = "public_c"
    }
}

resource "aws_route_table_association" "public_c_rt" {
  subnet_id = "${aws_subnet.public_subnet_c.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

# Private subnet resources
resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id = "${aws_subnet.public_subnet_a.id}"
}

resource "aws_route_table" "private_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat.id}"
  }

  tags {
    Name = "private_routing_table"
  }
}

resource "aws_subnet" "private_subnet_a" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.128.0/22"
    availability_zone = "us-west-2a"

    tags {
        Name = "private_a"
    }
}

resource "aws_route_table_association" "private_a_rt" {
  subnet_id = "${aws_subnet.private_subnet_a.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

resource "aws_subnet" "private_subnet_b" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.132.0/22"
    availability_zone = "us-west-2b"

    tags {
        Name = "private_b"
    }
}

resource "aws_route_table_association" "private_b_rt" {
  subnet_id = "${aws_subnet.private_subnet_b.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

resource "aws_subnet" "private_subnet_c" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.136.0/22"
    availability_zone = "us-west-2c"

    tags {
        Name = "private_c"
    }
}

resource "aws_route_table_association" "private_c_rt" {
  subnet_id = "${aws_subnet.private_subnet_c.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

# Bastion host
resource "aws_security_group" "bastion_sg" {
  name = "bastion_sg"
  description = "SG for bastion hosts"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "bastion_sg"
  }
}

resource "aws_instance" "bastion" {
  ami = "ami-5ec1673e"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  vpc_security_group_ids = ["${aws_security_group.bastion_sg.id}"]
  key_name = ""
  associate_public_ip_address = true

  tags {
    Name = "bastion"
  }
}

resource "aws_security_group" "db_sg" {
  name = "curriculum_db_sg"

  ingress = {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "db_sub_group" {
  name = "curriculum_db_sub_group"
  subnet_ids = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_c.id}"]
  tags = {
    Name = "curriculum_db_subnet_group"
  }
}

resource "aws_db_instance" "db" {
  allocated_storage = 5
  storage_type = "gp2"
  engine = "mariadb"
  engine_version = "10.0.24"
  instance_class = "db.t2.micro"
  name = "curriculum_db"
  username = "masteruser"
  password = "${var.db_pass}"
  vpc_security_group_ids = ["${aws_security_group.db_sg.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.db_sub_group.name}"
  publicly_accessible = false
  multi_az = false
}

resource "aws_security_group" "elb_sg" {
  name = "curriculum_elb_sg"
  description = "SG for curriculum ELB"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "curriculum_elb_sg"
  }
}

resource "aws_elb" "elb" {
  name = "curriculum"
  subnets = ["${aws_subnet.public_subnet_b.id}", "${aws_subnet.public_subnet_c.id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    target = "HTTP:80/"
    interval = 30
  }

  instances = ["${aws_instance.service_b.id}", "${aws_instance.service_c.id}"]
  security_groups = ["${aws_security_group.elb_sg.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 120
  connection_draining = true
  connection_draining_timeout = 60

  tags {
    Name = "curriculum"
    Service = "curriculum"
  }
}

resource "aws_security_group" "ws_sg" {
  name = "curriculum_sg"
  description = "SG for curriculum hosts"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "curriculum_sg"
  }
}

resource "aws_instance" "service_b" {
  ami = "ami-5ec1673e"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private_subnet_b.id}"
  vpc_security_group_ids = ["${aws_security_group.ws_sg.id}"]
  key_name = "dirac"
  associate_public_ip_address = false

  tags {
    Name = "webserver_b"
    Service = "curriculum"
  }

}

resource "aws_instance" "service_c" {
  ami = "ami-5ec1673e"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private_subnet_c.id}"
  vpc_security_group_ids = ["${aws_security_group.ws_sg.id}"]
  key_name = "dirac"
  associate_public_ip_address = false

  tags {
    Name = "webserver_c"
    Service = "curriculum"
  }

}
