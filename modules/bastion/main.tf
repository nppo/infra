locals {
  common_tags = {
    Project = var.project
    Environment = var.env
    ProvisionedBy = "Terraform"
  }
}

data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20200323"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  owners = ["099720109477"]
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "ssm.amazonaws.com",
      ]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name = "${var.project}-${var.env}-bastion"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.project}-${var.env}-bastion"
  role = aws_iam_role.this.name
}

resource "aws_security_group" "eduvpn_ssh" {
  name = "eduvpn-ssh"
  description = "Allows SSH access to EduVPN ranges"
  vpc_id = var.vpc_id

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["194.171.28.0/27", "194.171.16.0/27", "195.169.127.0/24", "195.169.126.0/23", "145.90.230.0/23", "145.101.60.0/23"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "this" {
  ami           = data.aws_ami.this.id
  instance_type = "t2.micro"

  monitoring = true
  subnet_id = var.subnet_id
  vpc_security_group_ids = ["${aws_security_group.eduvpn_ssh.id}"]

  #user_data = <<-EOF
  #            #!/bin/bash
  #            sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  #            EOF

  iam_instance_profile = aws_iam_instance_profile.this.name

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-bastion"})
  volume_tags = local.common_tags
}
