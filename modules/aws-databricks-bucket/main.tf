/**
 * Creates AWS S3 bucket that is writeable by Databricks
 */
variable "name" {
  description = "Name of the bucket"
}

variable "databricks_account_id" {
  type        = string
  default     = "414351767826"
  description = "Default databricks AWS Account ID"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources created"
}

variable "versioning" {
  default     = false
  description = "Either or not apply versioning for root bucket"
}

variable "force_destroy" {
  default     = false
  description = <<EOF
    Allows bucket to be destroyed by terraform even if it has data.
    It is discouraged to enable this option for critical data buckets.
  EOF
}

variable "region" {
  description = "Region where bucket is located"
}

resource "aws_s3_bucket" "this" {
  bucket = var.name
  region = var.region
  acl    = "private"

  force_destroy = var.force_destroy

  versioning {
    enabled = var.versioning
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket              = aws_s3_bucket.this.id
  ignore_public_acls  = true
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    actions = ["s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:PutObject",
    "s3:DeleteObject"]
    resources = [
      "${aws_s3_bucket.this.arn}/*",
      aws_s3_bucket.this.arn]
    principals {
      identifiers = ["arn:aws:iam::${var.databricks_account_id}:root"]
      type        = "AWS"
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket     = aws_s3_bucket.this.id
  policy     = data.aws_iam_policy_document.this.json
  depends_on = [aws_s3_bucket_public_access_block.this]
}

output "bucket" {
  value = aws_s3_bucket.this.bucket
}

output "arn" {
  value = aws_s3_bucket.this.arn
}