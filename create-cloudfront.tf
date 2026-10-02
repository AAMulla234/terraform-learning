# # ========== LOCALS ==========
# locals {
#   tags = {
#     Project     = "Static Website Hosting"
#     Environment = "Production"
#     ManagedBy   = "Terraform"
#   }
# }

# resource "aws_cloudfront_origin_access_control" "oac" {
#   name                              = "s3-oac"
#   description                       = "Origin access control for static website"
#   origin_access_control_origin_type = "s3"
#   signing_behavior                  = "always"
#   signing_protocol                  = "sigv4"
# }



# # S3 static website host via CDN - content delievery Network
# #
# resource "aws_cloudfront_distribution" "cdn" {
#   enabled             = true
#   default_root_object = "index.html"
#   origin {
#     domain_name = aws_s3_bucket.static-website-s3-bucket.bucket_regional_domain_name
#     origin_id   = "s3-origin"

#     origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
#   }

#   default_cache_behavior {
#     target_origin_id       = "s3-origin"
#     viewer_protocol_policy = "redirect-to-https"
#     allowed_methods        = ["GET", "HEAD"]
#     cached_methods         = ["GET", "HEAD"]

#     forwarded_values {
#       query_string = false
#       cookies {
#         forward = "none"
#       }
#     }

#     compress = true
#   }

#   viewer_certificate {
#     cloudfront_default_certificate = true # Use your custom ACM cert if needed
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }
#   tags = local.tags
# }


