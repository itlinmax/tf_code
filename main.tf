provider "aws" {
    region = "eu-central-1"
}

resource "aws_instance" "example" {
    ami = "ami-02d9d83052ced9fdd"
    instance_type = "t4g.nano"
    tags = {
        Name = "terraform-example"
    }
}
