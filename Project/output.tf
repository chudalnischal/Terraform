# Output the name of the S3 bucket
output "s3_bucket_name" {
  value = aws_s3_bucket.s3store.id  # Outputs the ID (name) of the S3 bucket created
}

# Output the domain name of the CloudFront distribution
output "cloudfront_distribution_domain_name" {
  value = aws_cloudfront_distribution.cloudfront.domain_name  # Outputs the domain name of the CloudFront distribution
}
