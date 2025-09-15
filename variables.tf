
variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The EC2 instance type for the GPU node."
  type        = string
  #default     = "g4dn.xlarge"
  default     = "g5.2xlarge"
}

variable "ebs_volume_size" {
  description = "The size of the persistent EBS volume in GB for application data."
  type        = number
  default     = 100
}

variable "allowed_ssh_cidr" {
  description = "The CIDR block allowed to access the instance via SSH (port 22). Use '0.0.0.0/0' for open access (not recommended)."
  type        = string
  default     = "0.0.0.0/0"
}
