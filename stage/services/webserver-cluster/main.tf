provider "aws" {
    region = "eu-central-1"
}

#resource "aws_instance" "example" {
#    ami = "ami-02d9d83052ced9fdd"
#    instance_type = "t4g.nano"
#    tags = {
#        Name = "terraform-example"
#    }
#    user_data = <<-EOF
#        #!/bin/bash
#        echo "Hello, World" > index.html
#        nohup busybox httpd -f -p ${var.server_port} &
#        EOF
#    user_data_replace_on_change = true
#    vpc_security_group_ids = [aws_security_group.instance.id]
#}

resource "aws_launch_template" "example" {
    name = "terraform_launch_template"
    image_id = "ami-02d9d83052ced9fdd"
    instance_type = "t4g.nano"
    vpc_security_group_ids = [aws_security_group.instance.id]
    user_data = base64encode(templatefile("./user-data.sh", {
        server_port = var.server_port
        db_address = data.terraform_remote_state.db.outputs.address
        db_port = data.terraform_remote_state.db.outputs.port
        })
    )
    lifecycle {
        create_before_destroy = true
    }
}
resource "aws_autoscaling_group" "example" {
    vpc_zone_identifier = data.aws_subnets.default.ids
    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"
    min_size = 2
    max_size = 10
    tag {
        key = "Name"
        value = "terraform-asg-example"
        propagate_at_launch = true
    }
    launch_template {
        id      = aws_launch_template.example.id
        version = "$Latest"
  }
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"
    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_security_group" "alb" {
    name = "terraform-example-alb"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
    filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
    }
}
data "terraform_remote_state" "db" {
    backend = "local"
    config = {
        path = "../../data-stores/mysql/terraform.tfstate"
    }
}

resource "aws_lb" "example" {
    name = "terraform-asg-example"
    load_balancer_type = "application"
    subnets = data.aws_subnets.default.ids
    security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    port = 80
    protocol = "HTTP"
    default_action {
        type = "fixed-response"
        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}
resource "aws_lb_target_group" "asg" {
    name = "terraform-asg-example"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id
        health_check {
            path = "/"
            protocol = "HTTP"
            matcher = "200"
            interval = 15
            timeout = 3
            healthy_threshold = 2
            unhealthy_threshold = 2
        }
}
resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100
    condition {
        path_pattern {
            values = ["*"]
        }
    }
action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
    }
}