provider "aws" { # this will show the providers details 
    region = "ca-central-1" # the region of the providers
}

resource "aws_instance" "machine" { #resource type name and what i am going to call
    ami = "ami-0c6d358ee9e264ff1" # ami number as it is free tier
    instance_type = "t2.micro" # the type of instance 

    tags { #tags name 
        Name = "terraform-first-ec2" # creating the name of the instances 
    }
} 