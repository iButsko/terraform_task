variable "bastion_key" {
  default     = "webserver1"
}

variable  "prefix"{
  default     = "bastion-butsko"
}

variable "ecr_image" {
  description = "ECR image"
  default = "043751989667.dkr.ecr.eu-central-1.amazonaws.com/webserver:latest"
}

variable "source_repo_name" {
    description = "repo name"
    type = string
    default = "ecs-ecr-cicd"
}

variable "source_repo_branch" {
    description = "repo branch"
    type = string
    default = "master"
}

variable "region" {
  description = "AWS Region where to provision VPC Network"
  default     = "eu-central-1"
}

variable "family_td" {
  description = "Family of the Task Definition"
  default     = "eu-central-1"
}

variable "env" {
  default = "dev"
}

variable "cluster_name_cicd" {
  description = "EC2 instance type"
  default     = "ECS-cluster"
}

variable "account_id" {
  default = "043751989667"
}
variable "container_name_build" {
  default = "webserver"
}