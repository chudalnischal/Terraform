terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ca-central-1"
}

# Create S3 bucket
resource "aws_s3_bucket" "s3store" {
  bucket = var.bucket_name
}

# Upload index.html to the S3 bucket
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.s3store.id
  key          = "index.html"
  source       = "website/index.html"
  etag         = filemd5("website/index.html")
  content_type = "text/html"
}

# Upload error.html to the S3 bucket
resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.s3store.id 
  key          = "error.html"
  source       = "website/error.html"
  etag         = filemd5("website/error.html")
  content_type = "text/html"
}

# Create CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Origin Access Identity for Static Website"
}

# Create CloudFront distribution
resource "aws_cloudfront_distribution" "cloudfront" {
  origin {
    domain_name = aws_s3_bucket.s3store.bucket_regional_domain_name
    origin_id   = var.bucket_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled      = true
  default_root_object  = var.website_index_document

  default_cache_behavior {
    target_origin_id       = var.bucket_name
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = "cloudfront"
    Environment = "Dev"
  }

}
# we are giving access the cloud front to acess the resources from the s3 bucket
resource "aws_s3_bucket_policy" "policy_for_bucket" {
  bucket = aws_s3_bucket.s3store.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "s3:GetObject"
        Effect = "Allow"
        Resource = "${aws_s3_bucket.s3store.arn}/*" # resource arn stands for amazone resource name 
        Principal = {
          CanonicalUser = aws_cloudfront_origin_access_identity.origin_access_identity.s3_canonical_user_id
        }
      }
    ]

  })
  
}