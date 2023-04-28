#Define AWS Region
variable "region" {
  description = "Infrastructure region"
  type        = string
  default     = "eu-central-1"
}
variable "subnet_cidr_private" {
  description = "cidr blocks for the private subnets"
  default     = ["10.110.99.0/27", "10.110.99.32/27", "10.110.99.64/27"]
  type        = list(any)
}
variable "availability_zone" {
  description = "availability zones for the private subnets"
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  type        = list(any)
}

variable "subnet_cidr_public" {
  description = "cidr block for the public subnets"
  default     = ["10.110.99.96/27", "10.110.99.128/27", "10.110.99.160/27"]
  type        = any
}