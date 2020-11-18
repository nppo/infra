locals {
  common_tags = {
    Project = var.project
    Environment = var.env
    ProvisionedBy = "Terraform"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-????????"]
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
  name = "${var.project}-bastion"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.project}-bastion"
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
    cidr_blocks = var.ipv4_eduvpn_ips
  }

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    ipv6_cidr_blocks = var.ipv6_eduvpn_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_kms_key" "bastion_encryption_key" {
  description = "Bastion EBS encryption key"
  tags = merge(local.common_tags, {Name="${var.project}-bastion-ebs-encryption-key"})
}

resource "aws_kms_alias" "db_encryption_key_alias" {
  name          = "alias/bastion-ebs-encryption-key"
  target_key_id = aws_kms_key.bastion_encryption_key.key_id
}

resource "aws_instance" "bastion-host" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  monitoring = true
  subnet_id = var.subnet_id
  vpc_security_group_ids = [
    aws_security_group.eduvpn_ssh.id,
    var.database_security_group,
    var.harvester_security_group,
    var.default_security_group_id
  ]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.this.name

  user_data = templatefile("${path.module}/bastion_setup.tpl", { public_keys = var.public_keys})

  root_block_device {
    encrypted = true
    kms_key_id = aws_kms_key.bastion_encryption_key.arn
  }

  tags = merge(local.common_tags, {Name = "${var.project}-bastion"})
  volume_tags = local.common_tags
}

resource "aws_eip" "bastion" {
  vpc = true
  instance = aws_instance.bastion-host.id

  tags = merge(local.common_tags, {Name = "${var.project}-bastion"})

  lifecycle {
    prevent_destroy = true
  }
}
