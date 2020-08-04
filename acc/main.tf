locals {
  project = "surfpol"
  env = "acc"
  ipv4_eduvpn_ips = ["145.90.230.0/23", "145.101.60.0/23"]
  ipv6_eduvpn_ips = ["2001:610:450:50::/60", "2001:610:3:2150::/60"]
  eduvpn_ips = concat(local.ipv4_eduvpn_ips, local.ipv6_eduvpn_ips)
  domain_name = "acc.surfedushare.nl"
  public_keys = {
    "fako": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSoemGsbpE//hs2yYquV79aIk/7zKAO1j9RBaLs0fUk6eThhOX1ONRAxyxkaR+rZT8PsSVGbH/m+OXCb1pDc4ddMulhjOV9KYUY7h5EXAPN+f0uxmecNahY5qhgtBZAs56NY9ZU5+rIS70F+3K1Acmbwvck7SMRCgCRPFCdO2Qyc3AyQqDSyUoALoqoJlleH282/FqfbAokbs/7MpaTeuqfOMSFLqCzTDQK3C8QsOirdfSORG5OofekJojq9yiBe7xQkLEaTl5EBEVsyMrK+5n2TAXEUfH6NvVqyv50faJ8LXNO4eq3vjmUybIPrbTA0h6p6PheuA+b5TTPexBFtVH fako@Fakos-MacBook-Pro.local",
    "jelmer": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDL+pYSi8xWN6YdSlNPmBR+Iu5XfRSufXmqrNMesQprU0fSNHE0PiLGv//4a7ZVh6uGCzmqbhQVHbAs50hbODe+Wd5LkNHPnAdu/7gT+Bx3IOwqrZgNyFYxzMRxzKeuxhIwZQjMQNfA79qY+kc/RUX+zaph9fDABbcC5IVDJtpSyPRfx0J3duEbk0opBKLHSV+5gXhyiA39zE7Gxe898AjsKPKClQAUclHYgSK/+U7XrUUMCBJXW/uPVsuO2o0QU9mGxdM0eYf12dP72izYz0wkde5vmVgOpa8UittIUjgrl6+Id2uAvvjIynV46tTOvp8FLe0v0sCsg2ao9tVejxdvYpctg636CtoHsRYbESUDaHrmP5L3NG2UM9J2UIw1e+wpbGGuxvDBTCQK+Pmj6Kn7vTpFfhB3g8+uyWCilVHvtQ0uQ+jjvErODb9GTV9Ozt7LZU1WXtGqC/ODqwg8Y+H5lMCHR4P/yUnP76m3w6Td1h3W+JddZBTGKPkVqtuwbwAxuXC7AH1tFUY6LIqXcnWOv5S59T52CTEMUS1pFY4Anlj7PfBHoNFr/p0+CeLswMRf8SCb+I6G9Cb3ch2BHtKv8aivxuFMmUhjmSrvdda12v5KULwQ+YogXJeahFaoGulc/e81nCPhC0sFFMsggenKCALcENUcDnyx0Lvt9w7myw== Jelmer'siPhone",
    "kirsten": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtreudPBChpjxasTP9IVQ5rOKMLsetchATrLTQjwQ1eNC/Io4CdBFuSPSE1y+p5UMc5NWYyv3MZ8yR+PmBNzdKpRvhGzOTVlbq0aprlue3nD5q8MjOD5Tzjtmnwrk5RQ9aaWK2hZ7ienVKZ6sh3re4052OheaeftBsqNeOKF7PYXlvZCsNVmcMiTHPdVLpgxCGIdjYJ2xVeuqEqYv7J57fCycnV47iRKHv6bCYuJTh26IaOacNKwhaf9n2+dBeSxZPq9VJBfxyPRgg0w7hqzIKx5Dp6VkDci7y2hxjPslwMCujPK6FIddMwDN42z0MXrIEfdb2GocfxTdvOO0XUINd kruys@zilverline.com",
    "ruben": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsXnT5E/IXrWD4JIWhyFxuKfeUTzkHjIDdZ/BPErhSw9vWa608aqvtGOZIpqZi/evpHy3WQxxn9z38eZY1LrnOfN6/9It9GTxeWLqVddHpC1d3AlqdA9Jvm02nrqCWgrnnkz0V3shS6TC/DWcPuL+teI79G5cOD4nfGNK7EYUl98iXphuobFuR8MRAzpkBhMWHtPJN49PU0ftYlytaXiKxlDHj5hq9hJAVgBV+CDK77mYDZpJvYJkKqLI1paRMPIowdI2JJCpGPbjhbihZG+tBXAnvUyBJyewcCfgs3RK4sfR1udXQWdOHXbP0mTvQJg+4uzimW3QV6iNh5Ttc6h8n ruben@Rubens-MacBook-Pro.fritz.box"
  }
}

terraform {
  required_version = "~> 0.12"
  backend "s3" {
    key = "acc/terraform.tfstate"
    region = "eu-central-1"
    bucket = "pol-acc-state"
    profile = "pol-acc"
  }
}

provider "aws" {
  version    = "~> 2.63"
  profile    = "pol-acc"
  region     = "eu-central-1"
}

resource "aws_iam_account_alias" "alias" {
  account_alias = "surfpol-acc"
}

module "user-access" {
  source = "../modules/user-access"

  users = {"fako.berkers@surfnet.nl" = ["superusers"]
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
  default_security_group_id = module.vpc.default_security_group_id
}

module "rds" {
  source = "../modules/rds"

  db_name = "edushare"
  project = local.project
  env = local.env

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}

module "ecs-cluster" {
  source = "../modules/ecs-cluster"

  project = local.project
  env = local.env
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
}

module "image-upload-bucket" {
  source = "../modules/image-upload-bucket"

  name = "search-portal-media-uploads-${local.env}"
  project = local.project
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
  elasticsearch_version = "7.4"
  instance_type = "m4.xlarge.elasticsearch"
  instance_count = 1
  instance_volume_size = 10
  vpc_id = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnet_ids[0]
  superuser_task_role_name = module.ecs-cluster.superuser_task_role_name
  application_task_role_name = module.ecs-cluster.application_task_role_name
  harvester_task_role_name = module.ecs-cluster.harvester_task_role_name
}

module "service" {
  source = "../modules/service"
  postgres_credentials_application_arn = module.rds.postgres_credentials_application_arn
  image_upload_bucket_arn = module.image-upload-bucket.image_bucket_arn
  application_task_role_arn = module.ecs-cluster.application_task_role_arn
  application_task_role_name = module.ecs-cluster.application_task_role_name
  django_secrets_arn = module.ecs-cluster.django_secrets_arn
}

module "harvester" {
  source = "../modules/harvester"
  postgres_credentials_application_arn = module.rds.postgres_credentials_application_arn
  harvester_task_role_name = module.ecs-cluster.harvester_task_role_name
  django_secrets_arn = module.ecs-cluster.django_secrets_arn
  subnet_ids = module.vpc.private_subnet_ids
}
