variable "name" {
  description = "Solution Name"
}

variable "vpc_id" {
  description = "Id of the VPC where to deploy the resources"
}

variable "public_vswitchs_ids" {
  type = "list"
  description = "Ids of the public vswitchs"
}

variable "private_vswitchs_ids" {
  type = "list"
  description = "Ids of the private vswitchs"
}

variable "ssh_password" {
  description = "Ssh password for the hosts"
}

variable "db_password" {
  description = "Db password for the account db gitlab"
}

variable "redis_connect" {
  description = "Redis endpoint for the access to managed service"
}

variable "redis_password" {
  description = "Redis password for the access to managed service"
}

variable "nas_mount_points" {
  type = "list"
  description = "Nas mount points of each public vswitches"
}