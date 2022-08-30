locals {
  project = "nppo"
  env = "acc"
  application_project = "nppo"
  application_mode = "acceptance"
  docker_registry = "870512711545.dkr.ecr.eu-central-1.amazonaws.com"
  ipv4_eduvpn_ips = ["145.90.230.0/23", "145.101.60.0/23"]
  ipv6_eduvpn_ips = ["2001:610:450:50::/60", "2001:610:3:2150::/60"]
  eduvpn_ips = concat(local.ipv4_eduvpn_ips, local.ipv6_eduvpn_ips)
  fargate_ips = ["3.70.31.125", "18.195.143.27"]
  public_keys = {
    "fako": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+BbIDLbS4QBfJZUyzg8FEFOGGOxt5EpIHc4NaTPjKIYsQfvRrKC6gNJR9Euoby0Jlm/T8ZXcONzylnYp62ZhY5+gp51wLhxsq9vg3wYbT2lPs2HIZ3PA99etmwneA3uffm9NrE16DDrAo2Z9qy3wup4wF9sVtT2i2quk+DMwbbVeGVjGQ7RoxeH/lo8wLW3Jx+TMMSoryDHalVNWrXZwOpZQVmTJD87E7jrzmJih+XQFNmvEkq7e/+QPs8P17w5Zv7BESPz8FZ3p6e85rLogCeIa5WqDx1oooUSLUhGNgI+xvcvCJ6LG5VUckKV+uI2mkoe6eIf3YF69HU6yWZ68YR3P9rk7QeAZom/LKQBlZt/eexCG6E9rz8cvqEBNgwTdI3LAj+NcByjktw/hpugF2PECH16cCR5nro83xHrxOeomDgL441FRHuP3SK5rdXwTL8SniN0KAe5FuXsq35eVNj0h7+F8NbHWZIEr4VxGJhehW/zkzrt6pWHeQxIZwEHk= fako@burte"
  }
}

terraform {
  required_version = "~> 1.2.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.57.0"
    }
  }
  backend "s3" {
    key = "acc/terraform.tfstate"
    region = "eu-central-1"
    bucket = "nppo-acc-state"
    profile = "nppo-acc"
  }
}

provider "aws" {
  profile    = "nppo-acc"
  region     = "eu-central-1"
}

resource "aws_iam_account_alias" "alias" {
  account_alias = "nppo-acc"
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

  users = { }
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

  db_name = "nppo"
  project = local.project
  env = local.env

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  monitoring_kms_key = aws_kms_key.monitoring_encryption_key.key_id
}

module "elasticsearch" {
  source = "../modules/elasticsearch"

  project = local.project
  env = local.env

  domain_name = "main"
  elasticsearch_version = "OpenSearch_1.2"
  instance_type = "r5.xlarge.elasticsearch"
  instance_count = 1
  instance_volume_size = 50
  vpc_id = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]
  default_security_group_id = module.vpc.default_security_group_id
  allowed_ips = concat(local.ipv4_eduvpn_ips, local.fargate_ips)
  superuser_task_role_name = module.ecs-cluster.superuser_task_role_name
  application_task_role_name = module.ecs-cluster.application_task_role_name
  harvester_task_role_name = module.ecs-cluster.harvester_task_role_name
  monitoring_kms_key = aws_kms_key.monitoring_encryption_key.key_id
}

module "search-service" {
  source = "../modules/search-service"

  env = local.env
  vpc_id = module.vpc.vpc_id
  application_task_role_arn = module.ecs-cluster.application_task_role_arn
  application_task_role_name = module.ecs-cluster.application_task_role_name
  superuser_task_role_name = module.ecs-cluster.superuser_task_role_name
  exec_policy_arn = module.ecs-cluster.exec_policy_arn
  monitoring_kms_key = aws_kms_key.monitoring_encryption_key.key_id
  harvester_api_key_arn = module.harvester.harvester_api_key_arn
  harvester_credentials_arn = module.harvester.harvester_credentials_arn
  opensearch_credentials_arn = module.elasticsearch.opensearch_credentials_arn
}

module "harvester" {
  source = "../modules/harvester"

  vpc_id = module.vpc.vpc_id
  harvester_task_role_name = module.ecs-cluster.harvester_task_role_name
  superuser_task_role_name = module.ecs-cluster.superuser_task_role_name
  exec_policy_arn = module.ecs-cluster.exec_policy_arn
  subnet_ids = module.vpc.public_subnet_ids
  harvester_content_bucket_name = "nppo-harvester-content-${local.env}"
  monitoring_kms_key = aws_kms_key.monitoring_encryption_key.key_id
  opensearch_credentials_arn = module.elasticsearch.opensearch_credentials_arn
}

module "middleware-service" {
  source = "../modules/middleware-service"

  env = local.env
  vpc_id = module.vpc.vpc_id
  application_task_role_name = module.ecs-cluster.middleware_task_role_name
  superuser_task_role_name = module.ecs-cluster.superuser_task_role_name
  exec_policy_arn = module.ecs-cluster.exec_policy_arn
  monitoring_kms_key = aws_kms_key.monitoring_encryption_key.key_id
  hva_pure_api_key_arn = module.harvester.hva_pure_api_key_arn
}

module "sources" {
  source = "../modules/sources"

  harvester_task_role_name = module.ecs-cluster.harvester_task_role_name
  middleware_task_role_name = module.ecs-cluster.middleware_task_role_name
  superuser_task_role_name = module.ecs-cluster.superuser_task_role_name
}

module "ecs-cluster" {
  source = "../modules/ecs-cluster"

  project = local.project
  env = local.env

  application_project = local.application_project
  application_mode = local.application_mode
  docker_registry = local.docker_registry

  service_target_group = module.load-balancer.search_target_group
  harvester_target_group = module.load-balancer.harvester_target_group
  flower_credentials_arn = module.harvester.flower_credentials_arn

  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  ecs_event_role = "arn:aws:iam::825135206789:role/ecsEventsRole"

  default_security_group = module.vpc.default_security_group_id
  postgres_access_security_group = module.rds.security_group_access_id
  opensearch_access_security_group = module.elasticsearch.elasticsearch_access_security_group
  redis_access_security_group = module.harvester.redis_access_security_group_id
  harvester_access_security_group = module.harvester.harvester_access_security_group_id
  harvester_protect_security_group = module.harvester.harvester_protect_security_group_id
  search_protect_security_group = module.search-service.search_protect_security_group_id
}

module "load-balancer" {
  source = "../modules/load-balancer"

  project = local.project
  env = local.env

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  eduvpn_ips = local.eduvpn_ips
  domain_name = "acc.publinova.nl"
  default_security_group_id = module.vpc.default_security_group_id
  harvester_access_security_group_id = module.harvester.harvester_access_security_group_id
  search_access_security_group_id = module.search-service.search_access_security_group_id
  middleware_access_security_group_id = module.middleware-service.middleware_access_security_group_id
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
