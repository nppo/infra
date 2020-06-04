# infra
Terraform code for SURFedushare

## How does it work?
Terraform checks your defined infrastructure against the current infrastructure. It will apply those changes to the running infrastructure to reflect your configuration.

## Prerequisites
Make sure you have installed terraform. Follow the instructions at [the terraform website](https://learn.hashicorp.com/terraform/getting-started/install.html).
Make sure the terraform version is compatible with the version defined in the terraform block in the `main.tf` file of the environment you want to configure. We currently request terraform `~> 0.63`.

### AWS
We are running our platform on Amazon Web Services (AWS).
Make sure you have access keys for the environment you want to configure. Those access keys have to be defines in your local `~/.aws/credentials` file. Use the correct profile depending on the environment.

Something like this:

```
[pol-dev]
aws_access_key_id=xxxx
aws_secret_access_key=xxxx

[pol-acc]
aws_access_key_id=xxxx
aws_secret_access_key=xxxx
```

## Setting up terraform
Before you can manage your infrastructure you have to initialize terraform. Go to the environment you want to initialize (dev, acc, prod) and run:

```
terraform init -backend-config=./backend.hcl
```

## Manage your infrastructure

To see what the consequences of your changes are run the following command:

```
terraform plan
```

It outputs the changes to your infrastructure. It does not perform them, so you can review if those changes reflect what you want to achieve.

When you are sure the proposed changes to your infrastructure are correct you can run the following command:

```
terraform apply
```

This command first shows the same output as `terraform plan`. However you can now apply the changes by typing `yes`. Now terraform will execute the plan and change your infrastructure.

**Warning: Some changes will destroy and create, instead of change a resource. Make sure this is what you want as it may cause data loss or downtime.**
