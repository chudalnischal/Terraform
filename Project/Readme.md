# Terraform Project for Static Website Hosting on AWS

## Overview

This Terraform project sets up a static website using AWS services. It involves creating an S3 bucket to store website files, uploading HTML files to the bucket, and configuring CloudFront for content delivery. The setup includes creating a CloudFront distribution for efficient content delivery and configuring necessary policies for secure access.

## Providers and Configuration

- **AWS Provider**: Configures Terraform to use AWS as the cloud provider. The region specified for deployment is `ca-central-1`.
- **S3 Bucket**: A bucket is created to store the static website files. The bucket name is defined using a variable (`bucket_name`).

## Resources

1. **S3 Bucket**
   - The S3 bucket is created with a name specified by a variable. This bucket will hold the website files.

2. **S3 Objects**
   - Two objects are uploaded to the S3 bucket:
     - `index.html`: The main page of the website.
     - `error.html`: A custom error page for handling 404 errors.
   - Both files are uploaded with specified content types and MD5 hashes.

3. **CloudFront Origin Access Identity**
   - An origin access identity is created for CloudFront to securely access the S3 bucket.

4. **CloudFront Distribution**
   - A CloudFront distribution is set up to serve content from the S3 bucket. It includes settings for:
     - Enabling IPv6 and HTTPS.
     - Redirecting HTTP requests to HTTPS.
     - Specifying caching behavior and TTL settings.
     - Using the default CloudFront certificate for HTTPS.

5. **S3 Bucket Policy**
   - A policy is applied to the S3 bucket to allow access from the CloudFront distribution. This policy ensures that only CloudFront can access the content in the bucket.

## Outputs

- **S3 Bucket Name**: Outputs the name of the created S3 bucket.
- **CloudFront Distribution Domain Name**: Outputs the domain name of the CloudFront distribution.

## Variables

- **`bucket_name`**: The name of the S3 bucket used for storing website files.
- **`website_index_document`**: Specifies the index document for the website.

## HTML Files

- **`index.html`**: The main HTML file for the website featuring basic styling and social media links.
- **`error.html`**: A custom 404 error page with styling and a link to return to the homepage.
