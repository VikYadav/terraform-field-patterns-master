/**
 * Creates AWS Cross-account IAM Role, where Databricks AWS account it is allowed to do `sts:AssumeRole`
 */
variable "prefix" {
  description = "Prefix for resources created for"
}

variable "databricks_account_id" {
  type        = string
  default     = "414351767826"
  description = "Default databricks AWS Account ID"
}

variable "external_id" {
  type        = string
  description = "External ID you find on https://accounts.cloud.databricks.com/#aws"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources created"
}

data "aws_iam_policy_document" "cross_account_policy" {
  statement {
    effect = "Allow"
    actions = ["ec2:AssociateDhcpOptions",
      "ec2:AssociateIamInstanceProfile",
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:AttachVolume",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CancelSpotInstanceRequests",
      "ec2:CreateDhcpOptions",
      "ec2:CreateInternetGateway",
      "ec2:CreateKeyPair",
      "ec2:CreateRoute",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateVpc",
      "ec2:DeleteInternetGateway",
      "ec2:DeleteKeyPair",
      "ec2:DeleteRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSubnet",
      "ec2:DeleteTags",
      "ec2:DeleteVolume",
      "ec2:DeleteVpc",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeNetworkAcls",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeIamInstanceProfileAssociations",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstances",
      "ec2:DescribePrefixLists",
      "ec2:DescribeReservedInstancesOfferings",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotInstanceRequests",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpcs",
      "ec2:DetachInternetGateway",
      "ec2:DisassociateIamInstanceProfile",
      "ec2:ModifyVpcAttribute",
      "ec2:ReplaceIamInstanceProfileAssociation",
      "ec2:RequestSpotInstances",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:CreatePlacementGroup",
      "ec2:DeletePlacementGroup",
    "ec2:DescribePlacementGroups"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = ["iam:CreateServiceLinkedRole",
    "iam:PutRolePolicy"]
    resources = [
    "arn:aws:iam::*:role/aws-service-role/spot.amazonaws.com/AWSServiceRoleForEC2Spot"]

    condition {
      test     = "StringLike"
      variable = "iam:AWSServiceName"
      values   = ["spot.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "cross_account_policy" {
  name   = "${var.prefix}-crossaccount-iam-policy"
  policy = data.aws_iam_policy_document.cross_account_policy.json
}

data "aws_iam_policy_document" "assume_role_for_databricks" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["arn:aws:iam::${var.databricks_account_id}:root"]
      type        = "AWS"
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

resource "aws_iam_role" "cross_account" {
  name               = "${var.prefix}-crossaccount-iam-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_for_databricks.json
  description        = "Grants Databricks full access to VPC resources"
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "cross_account" {
  policy_arn = aws_iam_policy.cross_account_policy.arn
  role       = aws_iam_role.cross_account.name
}

output "role_arn" {
  value = aws_iam_role.cross_account.arn
}

output "role_name" {
  value = aws_iam_role.cross_account.name
}