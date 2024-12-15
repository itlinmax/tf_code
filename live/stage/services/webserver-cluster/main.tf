provider "aws" {
    region = "eu-central-1"
    default_tags {
        tags = {
            Owner = "team-foo"
            ManagedBy = "Terraform"
        }
    }
}
module "webserver_cluster" {
    source = "../../../../modules/services/webserver-cluster"
    cluster_name = "webservers-stage"
    state_path = "../../data-stores/mysql/terraform.tfstate"
    instance_type = "t4g.nano"
    min_size = 2
    max_size = 2
    enable_autoscaling = false
    custom_tags = {
        Owner = "team-foo"
        ManagedBy = "terraform"
    }
}

resource "aws_security_group_rule" "allow_testing_inbound" {
    type = "ingress"
    security_group_id = module.webserver_cluster.alb_security_group_id
    from_port = 12345
    to_port = 12345
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
