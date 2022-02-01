variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "Yet Another Service"
}
variable "instance_type" {
  description = "Value of the Instance Type"
  type        = string
  default     = "m5.4xlarge"
  #default     = "t2.medium"
}

