
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
    name = "${var.cluster_name}-aws-launch-template"
    image_id = "ami-02d9d83052ced9fdd"
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.instance.id]
    user_data = base64encode(templatefile("${path.module}/user-data.sh", {
        server_port = local.http_port
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
    min_size = var.min_size
    max_size = var.max_size
    tag {
        key = "Name"
        value = "${var.cluster_name}-aws-autoscaling-group"
        propagate_at_launch = true
    }
    dynamic "tag" {
    for_each = var.custom_tags
        content {
            key = tag.key
            value = tag.value
            propagate_at_launch = true
        }
    }
    launch_template {
        id      = aws_launch_template.example.id
        version = "$Latest"
  }
}

resource "aws_security_group" "instance" {
    name = "${var.cluster_name}-aws-security-group-instance"
}

resource "aws_security_group" "alb" {
    name = "${var.cluster_name}-aws-security-group-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
    type = "ingress"
    security_group_id = aws_security_group.alb.id
    from_port = local.http_port
    to_port = local.http_port
    protocol = local.tcp_protocol
    cidr_blocks = local.all_ips
}
resource "aws_security_group_rule" "instance" {
    type = "ingress"
    security_group_id = aws_security_group.instance.id
    from_port = local.http_port
    to_port = local.http_port
    protocol = local.tcp_protocol
    cidr_blocks = local.all_ips
}
resource "aws_security_group_rule" "allow_all_outbound" {
    type = "egress"
    security_group_id = aws_security_group.alb.id
    from_port = local.any_port
    to_port = local.any_port
    protocol = local.any_protocol
    cidr_blocks = local.all_ips
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
        path = var.state_path
    }
}

resource "aws_lb" "example" {
    name = "${var.cluster_name}-aws-lb"
    load_balancer_type = "application"
    subnets = data.aws_subnets.default.ids
    security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    port = local.http_port
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
    name = "${var.cluster_name}-lb-target-group"
    port = local.http_port
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
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
    count = var.enable_autoscaling ? 1 : 0
    scheduled_action_name = "${var.cluster_name}-scale-out-during- business-hours"
    min_size = 2
    max_size = 10
    desired_capacity = 10
    recurrence = "0 9 * * *"
    autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
    count = var.enable_autoscaling ? 1 : 0
    scheduled_action_name = "${var.cluster_name}-scale-in-at- night"
    min_size = 2
    max_size = 10
    desired_capacity = 2
    recurrence = "0 17 * * *"
    autoscaling_group_name = aws_autoscaling_group.example.name
}
