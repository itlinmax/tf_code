data "aws_subnets" "default" {
    filter {
        name = "vpc-id"
        values = [var.vpc_id]
    }
}
