data "aws_subnet" "first" {
  id = element(data.aws_subnets.default.ids, 0)
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}