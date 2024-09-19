terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"   # Specifies the provider and its source
      version = "~> 5.0"           # Sets the provider version constraint
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ca-central-1"         # Specifies the AWS region to deploy resources in
}

# Create S3 bucket
resource "aws_s3_bucket" "s3store" {
  bucket = var.bucket_name         # Sets the name of the S3 bucket from a variable
}

# Upload index.html to the S3 bucket
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.s3store.id       # Specifies the bucket where the object will be stored
  key          = "index.html"                   # The key (path) for the object in S3
  source       = "website/index.html"           # Local path to the file being uploaded
  etag         = filemd5("website/index.html")  # Computes the MD5 hash of the file for use as an ETag
  content_type = "text/html"                     # Sets the content type of the object
}

# Upload error.html to the S3 bucket
resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.s3store.id       # Specifies the bucket where the object will be stored
  key          = "error.html"                   # The key (path) for the object in S3
  source       = "website/error.html"           # Local path to the file being uploaded
  etag         = filemd5("website/error.html")  # Computes the MD5 hash of the file for use as an ETag
  content_type = "text/html"                     # Sets the content type of the object
}

# Create CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Origin Access Identity for Static Website"  # Description for the CloudFront origin access identity
}

# Create CloudFront distribution
resource "aws_cloudfront_distribution" "cloudfront" {
  origin {
    domain_name = aws_s3_bucket.s3store.bucket_regional_domain_name  # S3 bucket domain name as the origin
    origin_id   = var.bucket_name                                      # Unique ID for the origin, using bucket name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path  # Configures access to S3 bucket through CloudFront
    }
  }

  enabled             = true                    # Enables the CloudFront distribution
  is_ipv6_enabled      = true                    # Enables IPv6 support
  default_root_object  = var.website_index_document  # Default root object served when accessing the distribution

  default_cache_behavior {
    target_origin_id       = var.bucket_name            # Specifies the target origin ID for the cache behavior
    viewer_protocol_policy = "redirect-to-https"       # Redirects HTTP requests to HTTPS
    allowed_methods        = ["GET", "HEAD"]           # Allowed methods for requests
    cached_methods         = ["GET", "HEAD"]           # Cached methods for requests

    forwarded_values {
      query_string = false                           # Does not forward query strings to the origin
      cookies {
        forward = "none"                             # Does not forward cookies to the origin
      }
    }

    min_ttl     = 0                                 # Minimum time-to-live (TTL) for cached objects
    default_ttl = 3600                              # Default TTL for cached objects
    max_ttl     = 86400                             # Maximum TTL for cached objects
  }

  viewer_certificate {
    cloudfront_default_certificate = true            # Uses the default CloudFront certificate for HTTPS
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"                       # No geo-restrictions applied
    }
  }

  tags = {
    Name        = "cloudfront"                       # Tag for identifying the CloudFront distribution
    Environment = "Dev"                              # Tag for environment identification
  }
}

# Set S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "policy_for_bucket" {
  bucket = aws_s3_bucket.s3store.id                    # Specifies the bucket to which the policy will be applied

  policy = jsonencode({
    Version = "2012-10-17"                             # Policy version
    Statement = [
      {
        Action = "s3:GetObject"                         # Action to allow access to objects
        Effect = "Allow"                               # Effect of the policy (allow or deny)
        Resource = "${aws_s3_bucket.s3store.arn}/*"     # Resource ARN for the objects in the bucket
        Principal = {
          CanonicalUser = aws_cloudfront_origin_access_identity.origin_access_identity.s3_canonical_user_id  # Canonical user ID for CloudFront to access S3
        }
      }
    ]
  })
}
