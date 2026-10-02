# Managed somewhere else, we just want to use in our project
#data "aws_s3_bucket" "my_external_bucket" {
#  bucket = "not-managed-by-us"
#}

data "aws_iam_policy_document" "static_website_read_policy" {
  statement {
    sid = "PublicReadGetObject"

    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static-website-s3-bucket.arn}/*"]
  }
}

resource "random_id" "s3_bucket_suffix" {
  byte_length = 4
}

# Actively managed by us
resource "aws_s3_bucket" "static-website-s3-bucket" {
  bucket        = "${local.project}-${random_id.s3_bucket_suffix.hex}-${var.bucket_name}"
  force_destroy = true
}


# Public Access Block (disable restrictions so CloudFront can read)
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.static-website-s3-bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 policy to allow to read public project.
# In GUI -> select bucket -> permission -> Policy and add JSON blob for permission


resource "aws_s3_bucket_policy" "static_website_public_read" {
  bucket = aws_s3_bucket.static-website-s3-bucket.id
  policy = data.aws_iam_policy_document.static_website_read_policy.json

  # policy = jsonencode({   // this old way of create policy...we use DATA here to create policy once and use multiple times
  #   Version = "2025-06-17"
  #   Statement = [
  #     {
  #       Sid       = "PublicReadGetObject"
  #       Effect    = "Allow"
  #       Principal = "*"
  #       Action    = "s3:GetObject"
  #       Resource  = "${aws_s3_bucket.static-website-s3-bucket.arn}/*"
  #     }
  #   ]
  # })
}

# Create Static website in S3, this resource is useful
resource "aws_s3_bucket_website_configuration" "static_website" {
  bucket = aws_s3_bucket.static-website-s3-bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.static-website-s3-bucket.id
  key          = "index.html"
  source       = "static-website/index.html"
  etag         = filemd5("static-website/index.html")
  content_type = "text/html"
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.static-website-s3-bucket.id
  key          = "error.html"
  source       = "static-website/error.html"
  etag         = filemd5("static-website/error.html")
  content_type = "text/html"
}

output "iam_policy" {
  value = data.aws_iam_policy_document.static_website_read_policy.json
}

output "s3_website_url" {
  value = aws_s3_bucket_website_configuration.static_website.website_endpoint
}
