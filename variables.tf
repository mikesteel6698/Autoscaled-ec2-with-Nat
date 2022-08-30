variable "ami_id" {
  type    = string
  default = "ami-08d4ac5b634553e16"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "test_vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"

}
variable "test_az" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "key" {
  type    = string
  default = "new"
}

variable "root_volume_size" {
  type    = number
  default = 10
}

variable "app_tags" {
  type    = string
  default = "webapp"
}

variable "db_tags" {
  type    = string
  default = "dbapp"
}