resource "aws_iam_user" "example" {
    count = 1
    name = var.user_name
}
variable "user_name" {
    description = "The user name to use"
    type = string
}

variable "give_neo_cloudwatch_full_access" {
    description = "If true, neo gets full access to CloudWatch"
    type = bool
}

output "all_arns" {
    value = aws_iam_user.example[0].arn
}
output "neo_cloudwatch_policy_arn" {
    value = one(concat(aws_iam_user_policy_attachment.neo_cloudwatch_full_access[*].policy_arn, aws_iam_user_policy_attachment.neo_cloudwatch_read_only[*].policy_arn))
}

resource "aws_iam_policy" "cloudwatch_read_only" {
    count = var.user_name == "neo"?1:0
    name = "cloudwatch-read-only-for-neo"
    policy = data.aws_iam_policy_document.cloudwatch_read_only.json
}

data "aws_iam_policy_document" "cloudwatch_read_only" {
    statement {
    effect = "Allow"
    actions = [
        "cloudwatch:Describe*",
        "cloudwatch:Get*",
        "cloudwatch:List*"
    ]
resources = ["*"]
    }
}

resource "aws_iam_policy" "cloudwatch_full_access" {
    count = var.user_name == "neo"?1:0
    name = "cloudwatch-full-access-for-neo"
    policy = data.aws_iam_policy_document.cloudwatch_full_access.json
}

data "aws_iam_policy_document" "cloudwatch_full_access" {
statement {
    effect = "Allow"
    actions = ["cloudwatch:*"]
    resources = ["*"]
    }
}

resource "aws_iam_user_policy_attachment" "neo_cloudwatch_full_access" {
    count = var.give_neo_cloudwatch_full_access&&var.user_name == "neo"?1:0
    user = aws_iam_user.example[0].name
    policy_arn = aws_iam_policy.cloudwatch_full_access[0].arn
}

resource "aws_iam_user_policy_attachment" "neo_cloudwatch_read_only" {
    count = !var.give_neo_cloudwatch_full_access&&var.user_name == "neo"?1:0
    user = aws_iam_user.example[0].name
    policy_arn = aws_iam_policy.cloudwatch_read_only[0].arn
}
