provider "aws" {
    region = "ca-central-1"
}

resource "aws_instance" "machine" {
    ami = "ami-0c6d358ee9e264ff1"
    instance_type = "t2.micro"

    tags {
        Name = "terraform-first-ec2"
    }
} 