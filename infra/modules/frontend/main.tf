resource "aws_s3_bucket" "frontend" {
  bucket = var.bucket_name
  tags = {
    Name = "Frontend Hosting"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.frontend.id
  index_document {
    suffix = "index.html"
  }
}

data "aws_iam_policy_document" "allow_cloudfront" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [var.cloudfront_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket     = aws_s3_bucket.frontend.id
  policy     = data.aws_iam_policy_document.allow_cloudfront.json
  depends_on = [aws_s3_bucket_public_access_block.block_public]
}
