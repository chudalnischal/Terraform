resource "aws_security_group" "sgroup" { # resource and label
    name = "terrafrom-security-group"\ #name of the security group

    ingress { #block specifies the rules for inbound traffic to the security group
        from_port = 8080 # traffic will be allowed through this port.
        to_port = 8080 # Since both from_port and to_port are set to 8080, this rule allows traffic only on port 8080.
        protocol = "tcp" # protocol
        CIDR = ["0.0.0.0/0"]  #  traffic is allowed from anywhere in the world, making it open to the public internet.
    }
}


provider "aws" { # this will show the providers details 
    region = "ca-central-1" # the region of the providers
}

resource "aws_instance" "machine" { #resource type name and what i am going to call
    ami = "ami-0c6d358ee9e264ff1" # ami number as it is free tier
    instance_type = "t2.micro" # the type of instance 
    vpc_security_group_id = [aws_security_group.sgroup.id] 
    # Attaches the previously defined security group (sgroup) to this EC2 instance.

    tags { #tags name 
        Name = "terraform-first-ec2" # creating the name of the instances 
    }
} 