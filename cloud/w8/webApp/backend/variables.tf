variable "bucket_name" {
  type    = string
  default = "state-bucket-phong"
}

variable "table_name" {
  type    = string
  default = "state-locking-table-phong"
}

variable "region" {
  type    = string
  default = "us-west-2"
}
