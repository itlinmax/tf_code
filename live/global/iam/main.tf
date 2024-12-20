provider "aws" {
    region = "eu-central-1"
}
module "users" {
    source = "../../../modules/landing-zone/iam-user"
    for_each = toset(var.user_names)
    user_name = each.value
    give_neo_cloudwatch_full_access = true
}

variable "user_names" {
    description = "Create IAM users with these names"
    type = list(string)
    default = ["maksim", "trinity", "morpheus", "galina", "darina", "neo"]
}

output "user_arns" {
    value = values(module.users)[*].all_arns
    description = "The ARNs of the created IAM users"
}

output "upper_names" {
    value = [for val in values(module.users)[*].all_arns : upper(val)]
}

output "neo_cloudwatch_policy_arn" {
 value = values(module.users)[*].neo_cloudwatch_policy_arn
}
