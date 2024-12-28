#variable "db_remote_state_bucket" {
#    description = "The name of the S3 bucket for the database's remote state"
#    type = string
#}
#variable "db_remote_state_key" {
#    description = "The path for the database's remote state in S3"
#    type = string
#}

variable "state_path" {
    description = "path to state file"
    type = string
}
variable "environment" {
    description = "The name of the environment we're deploying to"
    type = string
}

variable "ami" {
    description = "ami id"
    type = string
    default = "ami-02d9d83052ced9fdd"
}
variable "instance_type" {
    description = "The type of EC2 Instances to run (e.g.  t2.micro)"
    type = string
}

variable "server_port" {
    description = "Server port"
    type = number
}

variable "server_text" {
    description = "Server text"
    type = string
}
variable "min_size" {
    description = "The minimum number of EC2 Instances in the ASG"
    type = number
}
variable "max_size" {
    description = "The maximum number of EC2 Instances in the ASG"
    type = number
}
variable "enable_autoscaling" {
    description = "If set to true, enable auto scaling"
    type = bool
}
variable "custom_tags" {
    description = "Custom tags to set on the Instances in the ASG"
    type = map(string)
    default = {}
}
