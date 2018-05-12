variable "project_name" {
  description = "this name will be used to name resources"
  default = "artifactory"
}

variable "aws_ec2_instance_type" {
  description = "profile name configured in ~/.aws/credentials file"
  default = "t2.medium"
}

variable "aws_ec2_subnet_tag_name" {
  description = "aws private subnet tag name"
  default = "private-us-west-2c"
}

variable "boot_disk_size" {
  description = "boot disk size in GB"
  default = 20
}

variable "boot_disk_type" {
  description = "boot disk type in GB"
  default = "standard"
}

variable "artifactory_data_disk_size" {
  description = "artifactory data disk size in GB"
  default = 50
}

variable "artifactory_data_disk_type" {
  description = "artifactory data disk type in GB"
  default = "standard"
}

variable "postgres_data_disk_size" {
  description = "postgres data disk size in GB"
  default = 20
}

variable "postgres_data_disk_type" {
  description = "postgres data disk type in GB"
  default = "standard"
}

variable "aws_ec2_keypair" {
  description = "aws ec2 keypair"
}

variable "artifactory_domain_name" {
  description = "domain name for R53 dns record creation"
}

variable "postgres_password" {
  description = "postgres db password"
}

variable "docker_compose_version" {
  description = "docker compose version"
  default = "1.21.2"
}

variable "postgres_docker_image" {
  description = "postgres docker image"
  default = "postgres:9.5.2"
}

variable "artifactory_docker_image" {
  description = "artifactory docker image"
  default = "artifactory-oss:5.11.0"
}

variable "ec2_termination_protection" {
  description = "Protect artifactory instance from termination. `terraform destroy` will not delete"
  default = false
}
