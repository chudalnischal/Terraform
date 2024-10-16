# this terraform code is for storing the Terraform State file
## Terraform State file is a JSON format file which records the mapping from the  terraform resources in your configuration files. 

## Everytime you run the Terraform code it will compare with the Terraform code you used before and track and made changes according to it. 

## Terraform State file format is a private API that is meant only for internal use within Terraform .

## No one should never edit the terraform state filr by hand or write code that reads them directly. 

# Why to use Amazoe S3 bucket for storing the tfstate file? 
# => IT is already managed service so you dont need to worry about deploy and manage extra infrastructure. 
#    It is designed for durability and availability. 
#    It supports encryption which helps us to keep the ensitive data secure. 
#    It supports versionning which help us to revert back to old version if in need. 
#    It inexpensive


provider "aws" {
    region = "ca-central-1"

}

resource "aws_s3_bucket" "fileStore" {
    bucket = "storing-for-tfstate-file" #bucketname

    lifecycle {
      prevent_destroy = false
      #prevent accidental destroy
    }
  
}
 # versioning of the files
resource "aws_s3_bucket_versioning" "enableVersion" {
  bucket = aws_s3_bucket.fileStore.id
  versioning_configuration {
    status = "Enabled"
  }
}

# this ensures that any files stored in the s3 bucket is encrypted
resource "aws_s3_bucket_server_side_encryption_configuration" "lockingFiles" {
    bucket = aws_s3_bucket.fileStore.id # granting the bucket id 
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  
}
# eventhough the s3 bucket is private we are adding security layers so that not even the team members can make it public as it contains the sensitive file
resource "aws_s3_bucket_public_access_block" "pubAccess" {
    bucket = aws_s3_bucket.fileStore.id
    block_public_policy = true # enabling the policy
    block_public_acls = true # it will block the acl 
    ignore_public_acls = true # it ignore public access control list
    restrict_public_buckets = true
}
# creating the table for the dynamoDB
resource "aws_dynamodb_table" "name" {
  name = "Lock-for-the-s3" # name of the table
  billing_mode = "PAY_PER_REQUEST" # the billing mode
  hash_key = "LockID" #hash key

  attribute {
    name = "LockID"
    type = "S"
  }
}