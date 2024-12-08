provider "aws" {
    region = "eu-central-1"
}
resource "aws_db_instance" "example" {
    identifier_prefix = "terraform-up-and-running"
    engine = "mysql"
    allocated_storage = 10
    instance_class = "db.m5.large"
    skip_final_snapshot = true
    db_name = "example_database"
    username = var.db_username
    password = var.db_password
}
