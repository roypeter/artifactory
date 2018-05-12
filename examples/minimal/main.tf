provider "aws" {
  region  = "us-west-2"
}

module "aritfactory" {
  source = "../../"

  project_name = "aritfactory"
  artifactory_domain_name = "aritfactory.example.com"
  postgres_password = "pass it as variable"
  aws_ec2_keypair = "my key pair name"
}
