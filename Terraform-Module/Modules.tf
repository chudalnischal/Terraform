#Any set of Terraform configuration files in a folder is basically a module in terraform. 

# Folder Structure fro learning Modules


# terraform/
# ├── module/
# │   ├── main.tf
# │   ├── variables.tf
# │   ├── outputs.tf
# │   └── example.txt
# └── Project/
#     └── main.tf

module "new_module" {
  source = "./Project"# specifies the path to the module 
}

# Module Inputs
# Even though we have created a module and initilaize it with terraform init command 
#There is a problem with the /project folder : all the names are hardcoded. 

## if we use the module more than once in an account, it will return with name conflict  error.
#To avoid this, we can use the input variables in the module.

# we have to add a variable.tf file in the folder where we want to import the terraform module.
# /module/varaiables.tf
variable "cluster_name" {
description = "The name of the cluster"
type = string
}

# once you have created a variable.tf file, you can use the variable in the module block in the main.tf file. 
# but before that you have to add this variable in the main.tf of the folder from which you are making it as a module
# suppose i have this configuration in the main.tf of the folder /module

# security group just for load balancer 
# /module/main.tf
resource "aws_security_group" "lb_securitygroup" {
    name = "security_for_lb" # instead of this i will write 
    # name = "${var.cluster_name}-security_for_lb" 

    # inbound traffic
    ingress {
        from_port = 80 
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    # outbound traffic
    egress {
        from_port = 80
        to_port = 80 
        protocol = "-1" # "-1" means all protocols
        cidr_blocks = ["0.0.0.0/0"]

    }
}
# what it will do is it will create a security group with the name of the cluster name and then the security group name.
# which will avoid the name conflict error in the main.tf file of the folder where we are importing the module.

#so we have a file in /module and we are replacing the hardcoded name with the variable name in the /project/main.tf file.
# /project/main.tf
module "new_module" {
  source = "./module"# specifies the path to the module 
  
  cluster_name = "staging-cluster"
}


# so far we have added some input variables in the main.tf file of the folder where we are importing the module.
# but this are just few variables as we are implementing it just for learning purpose.
# but in real world enviroment, we may need to add more input variable and make changes according to it. 

# so we can add a variable.tf file in the specific folder and add all the input variables in it.
# and then make changes to the main.tf file of the folder from where we are importing the module.
# then pass this input variables in the module block in the main.tf file where we are using the terraform module block.

# Module Locals 
# Locals are used to declare a value that can be reused throughout the module.
# There are some values that are used multiple times in the module, so we can use the locals to declare them. 

# if you use the input variables there is a chance that the value of the variable can be changed by the user.
# but if you use the locals, the value of the local variable will not be changed by the user.

#syntax: 
# we are using the example that we have used in the input variables and modules.
# /project/main.tf
locals {
    http_port = 80
    any_port = 0 
    tcp_protocol = "tcp" 
}

# now we can use these local variables in the resource block of the module.
 # /project/main.tf
resource "aws_security_group" "lb_securitygroup" {
    name = "security_for_lb" # instead of this i will write 
    # name = "${var.cluster_name}-security_for_lb" 

    # inbound traffic
    ingress {
        from_port = local.http_port # using the local in the resource in the main.tf file
        to_port = local.http_port
        protocol = local.tcp_protocol
        cidr_blocks = ["0.0.0.0/0"]
    }
} 

# Module Outputs:
# Outputs are used to return the value of a resource to the user.

# First what we need to do it that we need to output the value of which we want in the output.tf file in the root folder.
# /module/outputs.tf

output "s3_bucket_name" {
  value = aws_s3_bucket.s3store.id  # Outputs the ID (name) of the S3 bucket created
  description = "value of the s3 bucket name"
}

# Next Step is to import the output value in the main.tf file of the folder where we are importing the module.
# /project/main.tf 
#syntax
module.<modulename>.<outputname> 

# for this example we can import the output value and used anywhere 
module.newModule.s3_bucket_name 

# you can also output the value  
output "modulebucket_name" {
    value = moduele.newModule.s3_bucket_name
    description = "value of the bucket name which is inported from the module folder and outputed"
}



# Important Module Gotchas

# 1. File Paths: 
# The path to the module must be relative to the root module.

path.module # This is a built-in Terraform variable that points to the directory where the current module is located.
# you ensure that file paths are always relative to the module itself, regardless of where the module is called from
/project/main.tf
resource "local_file" "example" {
  filename = "${path.module}/example-output.txt" # Output file in the module folder
  content  = file("${path.module}/example.txt") # Read the local file
}

# filename = "${path.module}/example-output.txt": Specifies the output file path relative to the module's location.
# file("${path.module}/example.txt"): Reads the content of example.txt from the module directory.

# 2. Inline Blocks:
# An inline block is an argument you set within a resource of the format:
# For example: 
resource "xxx" "yyy" {
 <NAME> {
 [CONFIG...]
 }
}  # where name is the inline block name and config is the configuration of the inline block.

# taking the example f the security group: 
# you can define all the confguration in the inline block like ingress, egress etc.  or you can define a seperate resource block for each of them.
#

#Note: do not mix inline blocks with separate resource blocks in the same resource it may override the configuration.
# This is the example of inline block with local variables.
/module/main.tf
resource "aws_security_group" "alb" {
 name = "${var.cluster_name}-alb"
  ingress {
    from_port = local.http_port
    to_port = local.http_port
    protocol = local.tcp_protocol
    cidr_blocks = local.all_ips
 }
 egress {
   from_port = local.any_port
   to_port = local.any_port
   protocol = local.any_protocol
   cidr_blocks = local.all_ips
 }
}

# this is th eeample of the same configuration with the seperate resource block.
/module/main.tf
resource "aws_security_group" "alb" {
 name = "${var.cluster_name}-alb"
}
resource "aws_security_group_rule" "allow_http_inbound" {
 type = "ingress"
 security_group_id = aws_security_group.alb.id

 from_port = local.http_port
 to_port = local.http_port
 protocol = local.tcp_protocol
 cidr_blocks = local.all_ips
}
resource "aws_security_group_rule" "allow_all_outbound" {
 type = "egress"
 security_group_id = aws_security_group.alb.id

 from_port = local.any_port
 to_port = local.any_port
 protocol = local.any_protocol
 cidr_blocks = local.all_ips
}


# Now if i want to add the extra configuration in the security group for the project folder then i can do it like this 
/project/main.tf

module "new_module" {
  source = "./module"
  cluster_name = "staging-cluster"
}

resource "aws_security_group_rule" "extra_rule" {
    type = "ingress"
    security_group_id = module.new_module.<outputed_security_group_id_from_rootFolder>
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

# 3. Module Versioning:
# Terraform modules can be versioned using version constraints in the module block.
# This is useful when you want to ensure that a specific version of a module is used in your configuration.

# best way is to use the Github repository for the module and then use the versioning in the module block.
# we can also tag the version in the github repository and then use the version in the module block.