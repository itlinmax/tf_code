provider "aws" {
    region = "eu-central-1"
}
module "webserver_cluster" {
    source = "../../../../modules/services/webserver-cluster"
    cluster_name = "webservers-stage"
    state_path = "../../data-stores/mysql/terraform.tfstate"
    instance_type = "t4g.nano"
    min_size = 2
    max_size = 2
}
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
    scheduled_action_name = "scale-out-during-business-hours"
    min_size = 2
    max_size = 10
    desired_capacity = 10
    recurrence = "0 9 * * *"
    autoscaling_group_name = module.webserver_cluster.asg_name
}
resource "aws_autoscaling_schedule" "scale_in_at_night" {
    scheduled_action_name = "scale-in-at-night"
    min_size = 2
    max_size = 10
    desired_capacity = 2
    recurrence = "0 17 * * *"
    autoscaling_group_name = module.webserver_cluster.asg_name
} 
resource "aws_security_group_rule" "allow_testing_inbound" {
    type = "ingress"
    security_group_id = module.webserver_cluster.alb_security_group_id
    from_port = 12345
    to_port = 12345
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
