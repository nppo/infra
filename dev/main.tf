locals {
  project = "surfpol"
  env = "dev"
  ipv4_eduvpn_ips = ["145.90.230.0/23", "145.101.60.0/23"]
  ipv6_eduvpn_ips = ["2001:610:450:50::/60", "2001:610:3:2150::/60"]
  eduvpn_ips = concat(local.ipv4_eduvpn_ips, local.ipv6_eduvpn_ips)
  domain_name = "dev.surfedushare.nl"
  public_keys = {
    "fako": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+BbIDLbS4QBfJZUyzg8FEFOGGOxt5EpIHc4NaTPjKIYsQfvRrKC6gNJR9Euoby0Jlm/T8ZXcONzylnYp62ZhY5+gp51wLhxsq9vg3wYbT2lPs2HIZ3PA99etmwneA3uffm9NrE16DDrAo2Z9qy3wup4wF9sVtT2i2quk+DMwbbVeGVjGQ7RoxeH/lo8wLW3Jx+TMMSoryDHalVNWrXZwOpZQVmTJD87E7jrzmJih+XQFNmvEkq7e/+QPs8P17w5Zv7BESPz8FZ3p6e85rLogCeIa5WqDx1oooUSLUhGNgI+xvcvCJ6LG5VUckKV+uI2mkoe6eIf3YF69HU6yWZ68YR3P9rk7QeAZom/LKQBlZt/eexCG6E9rz8cvqEBNgwTdI3LAj+NcByjktw/hpugF2PECH16cCR5nro83xHrxOeomDgL441FRHuP3SK5rdXwTL8SniN0KAe5FuXsq35eVNj0h7+F8NbHWZIEr4VxGJhehW/zkzrt6pWHeQxIZwEHk= fako@burte",
    "jelmer": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDp9Lxipp7WllbJG6zUSSJVgAmuJ26ShIspOUiaUoMY4qIi/imXveXOFnrYFdpjiQXtj4sFlKdybcmLle7wHwSLOcYM/SdpWOkyjucyZRVhg1a8nKu60C+ndXWEBqEZgcrbhX71b10Vc19HmsoQGdmhAf66Ck57WhsYiENmb3VUtWvMXfghGdE4x8te8Tm74ospsbcMUQXKrgz7EvI0k+XDo/L20w9AmiECdgpzXPEKnaTIGNAReJ44/4FAfMN3h0Kd72cHW9IGo5gcEStYbpIcGQ8dGdi5g/cLzyQdm2jSPq/u8DmJwf2dD8u8bevqQBcMGIGVYl7JrpAKO5CIlABa+PDFELca8/xg0fMOCtQMDSy0W0suQEZK7/QlNeWQNgGW8Ui4CSrWYvkdj24CrDSoHxf0a7YGGtP/Yc/Ry0dJkmmTrcogdaBHuHPjKylRAU3n2EXSnni+tZqnLtY3FYg/XrpuKPW1bqxQ6n8NSMrH1p/ZfHrgeYps7fqqp27yCwa7eovXi8AutQxWtZ6iUmP5dbBTwrp3EihHJ2xFtKAN5GltMzqaN0+8h9x/YRvncee9qGitetNG/8zqaXBXog/JS3faayAjEhELbAGHHQ4Q/YfHcNBhGYI3o/TACopNVZS+dAKErmJKmffN6hj3DoNdbFedPnamS6cK+JMdzPcFaw== jelmer.deronde@surfnet.nl",
    "kirsten": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtreudPBChpjxasTP9IVQ5rOKMLsetchATrLTQjwQ1eNC/Io4CdBFuSPSE1y+p5UMc5NWYyv3MZ8yR+PmBNzdKpRvhGzOTVlbq0aprlue3nD5q8MjOD5Tzjtmnwrk5RQ9aaWK2hZ7ienVKZ6sh3re4052OheaeftBsqNeOKF7PYXlvZCsNVmcMiTHPdVLpgxCGIdjYJ2xVeuqEqYv7J57fCycnV47iRKHv6bCYuJTh26IaOacNKwhaf9n2+dBeSxZPq9VJBfxyPRgg0w7hqzIKx5Dp6VkDci7y2hxjPslwMCujPK6FIddMwDN42z0MXrIEfdb2GocfxTdvOO0XUINd kruys@zilverline.com",
    "ruben": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsXnT5E/IXrWD4JIWhyFxuKfeUTzkHjIDdZ/BPErhSw9vWa608aqvtGOZIpqZi/evpHy3WQxxn9z38eZY1LrnOfN6/9It9GTxeWLqVddHpC1d3AlqdA9Jvm02nrqCWgrnnkz0V3shS6TC/DWcPuL+teI79G5cOD4nfGNK7EYUl98iXphuobFuR8MRAzpkBhMWHtPJN49PU0ftYlytaXiKxlDHj5hq9hJAVgBV+CDK77mYDZpJvYJkKqLI1paRMPIowdI2JJCpGPbjhbihZG+tBXAnvUyBJyewcCfgs3RK4sfR1udXQWdOHXbP0mTvQJg+4uzimW3QV6iNh5Ttc6h8n ruben@Rubens-MacBook-Pro.fritz.box",
    "frans": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDObOs3wiHKuNUOaXBGA059zcTZE2l4qPDjkyjaTnDRwrrqhWNPFq2FkFBJX6kjqt0TcbJ1YIWZlrEHtQLLLDXQhHg45hGwDQbR1ao7umC4i7lfUzI69AQx4keIwcUCTuTxlgA52AX6Qn9F6u3oRlHXxir2Vxsx3b6qENXkBFkfTg3t41YhkR8GW6OWrqHN/1GZYMDmE9RV91kT38MmvtDb0yNPI1hih4vuadPQpjEae4Ets16J21csVzxbn+r3vpcZmNL1ClhB873k4KlEzkP9DxuWVuw5daVfRRCE3xbo6H95yu3GXF7OrgGMdEeBHEtrvjJT32lDaOaJLPhQIijH frans.ward@surfnet.nl"
  }
}

terraform {
  required_version = "~> 0.12"
  backend "s3" {
    key = "dev/terraform.tfstate"
    region = "eu-central-1"
    bucket = "edu-state"
    profile = "pol-dev"
  }
}

provider "aws" {
  version    = "~> 3.12"
  profile    = "pol-dev"
  region     = "eu-central-1"
}

resource "aws_iam_account_alias" "alias" {
  account_alias = "surfpol-dev"
}

resource "aws_kms_key" "monitoring_encryption_key" {
  description = "Monitoring encryption key"
}

resource "aws_kms_alias" "monitoring_encryption_key_alias" {
  name          = "alias/monitoring-encryption-key"
  target_key_id = aws_kms_key.monitoring_encryption_key.key_id
}

module "user-access" {
  source = "../modules/user-access"

  users = {"FakoBerkers" = ["superusers"]
           "kruys@zilverline.com" = ["superusers"]
           "rhartog@zilverline.com" = ["superusers"]}
}

module "vpc" {
  source = "../modules/vpc"

  project = local.project
  env = local.env
  cidr = "10.0.0.0/16"

  azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  ipv4_eduvpn_ips = local.ipv4_eduvpn_ips
  ipv6_eduvpn_ips = local.ipv6_eduvpn_ips
  public_keys = local.public_keys
}

module "rds" {
  source = "../modules/rds"

  db_name = "edushare"
  project = local.project
  env = local.env

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  monitoring_kms_key = aws_kms_key.monitoring_encryption_key.key_id
}

module "ecs-cluster" {
  source = "../modules/ecs-cluster"

  project = local.project
  env = local.env
}

# This should be deleted, but we don't have access to it
module "log_group" {
  source = "../modules/log-group"

  project = local.project
  env = local.env
  retention_in_days = 14
}

module "elasticsearch" {
  source = "../modules/elasticsearch"

  project = local.project
  env = local.env

  domain_name = "main"
  elasticsearch_version = "7.9"
  instance_type = "m5.xlarge.elasticsearch"
  instance_count = 1
  instance_volume_size = 10
  vpc_id = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnet_ids[0]
  superuser_task_role_name = module.ecs-cluster.superuser_task_role_name
  application_task_role_name = module.ecs-cluster.application_task_role_name
  harvester_task_role_name = module.ecs-cluster.harvester_task_role_name
  monitoring_kms_key = aws_kms_key.monitoring_encryption_key.key_id
}

module "service" {
  source = "../modules/service"

  env = local.env
  vpc_id = module.vpc.vpc_id
  application_task_role_arn = module.ecs-cluster.application_task_role_arn
  application_task_role_name = module.ecs-cluster.application_task_role_name
  superuser_task_role_name = module.ecs-cluster.superuser_task_role_name
  monitoring_kms_key = aws_kms_key.monitoring_encryption_key.key_id
  harvester_bucket_arn = module.harvester.harvester_bucket_arn
}

module "harvester" {
  source = "../modules/harvester"

  vpc_id = module.vpc.vpc_id
  harvester_task_role_name = module.ecs-cluster.harvester_task_role_name
  subnet_ids = module.vpc.private_subnet_ids
  harvester_content_bucket_name = "surfpol-harvester-content-${local.env}"
  monitoring_kms_key = aws_kms_key.monitoring_encryption_key.key_id
}

module "load-balancer" {
  source = "../modules/load-balancer"

  project = local.project
  env = local.env

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  eduvpn_ips = local.eduvpn_ips
  domain_name = local.domain_name
  default_security_group_id = module.vpc.default_security_group_id
  service_access_security_group_id = module.service.service_access_security_group_id
  monitoring_kms_key = aws_kms_key.monitoring_encryption_key.key_id
}

module "bastion" {
  source = "../modules/bastion"

  project = local.project
  env = local.env

  vpc_id = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]
  ipv4_eduvpn_ips = local.ipv4_eduvpn_ips
  ipv6_eduvpn_ips = local.ipv6_eduvpn_ips
  public_keys = local.public_keys
  database_security_group = module.rds.security_group_access_id
  harvester_security_group = module.harvester.harvester_access_security_group_id
  default_security_group_id = module.vpc.default_security_group_id
}
