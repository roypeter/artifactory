data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user_data.tpl")}"
  vars {
    postgres_password = "${var.postgres_password}"
    docker_compose_version = "${var.docker_compose_version}"
    postgres_docker_image = "${var.postgres_docker_image}"
    artifactory_docker_image = "${var.artifactory_docker_image}"
  }
}

data "aws_subnet" "ec2" {
  filter {
    name   = "tag:Name"
    values = ["*${var.aws_ec2_subnet_tag_name}*"]
  }
}

data "aws_route53_zone" "selected" {
  name         = "${element(split(".", var.artifactory_domain_name), 1)}.${element(split(".", var.artifactory_domain_name), 2)}."
}

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2"
  description = "${var.project_name}-ec2"
  vpc_id      = "${data.aws_subnet.ec2.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8","192.168.0.0/16", "172.16.0.0/12"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8","192.168.0.0/16", "172.16.0.0/12"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.aws_ec2_instance_type}"
  subnet_id     = "${data.aws_subnet.ec2.id}"
  user_data     = "${data.template_file.user_data.rendered}"
  vpc_security_group_ids      = ["${aws_security_group.ec2.id}"]
  key_name = "${var.aws_ec2_keypair}"
  disable_api_termination = "${var.ec2_termination_protection}"

  root_block_device = {
    volume_type = "${var.boot_disk_type}"
    volume_size = "${var.boot_disk_size}"
    delete_on_termination = true
  }

  ebs_block_device {
    device_name = "/dev/xvdf"
    volume_type = "${var.artifactory_data_disk_type}"
    volume_size = "${var.artifactory_data_disk_size}"
    delete_on_termination = false
  }

  ebs_block_device {
    device_name = "/dev/xvdh"
    volume_type = "${var.postgres_data_disk_type}"
    volume_size = "${var.postgres_data_disk_size}"
    delete_on_termination = false
  }

  tags {
    Name = "${var.project_name}"
  }
}

resource "aws_route53_record" "gitlab" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${var.artifactory_domain_name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.ec2.private_ip}"]
}
