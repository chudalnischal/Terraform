variable "bucket_name" {
  description = "bucket name for s3"  
  default = "bucket001278"
}

variable "website_index_document" {
    description = "This is the website index html"
    default = "index.html"
    type = string
 
}
