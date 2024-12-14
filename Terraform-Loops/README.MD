Loops, If Statement, Zero Downtime Deployement & Terraform Gotchas

Loops
Terraform offers several different looping constructs. each intendent to be used in slightly different scenarios. 

1. count To loop over resources and modules
2. for_each: to loop over resources, inline blocks within a resources and modules
3. for: to loop over list and maps
4. for string: to loop over list and map within a string 


## loops with Count 

COunt is used inside the resources block. 
Suppose i want to create a IAM user using terraform . it is so easy to create a single user. But what if i need to create multiple users . In this type of case we use count in terraform. Basically, it loop over resources and modules which makes us easy to scale resources.

/iam/main.tf 
 resource "aws_iam_user" "example" {
    count = 3
    name = "neo"
 }
One Problem with this code is that, this will create 3 users with the same name. 
to over come this issue , we can use index with the count inside the resources. 
i.e 
/iam/main.tf 
 resource "aws_iam_user" "example" {
    count = 3
    name = "neo.${count.index}"
 }
so what it will do is it will create the 3 user with names neo.1, neo.2 and neo.3. But having this type of name is little complicated. so lets create a variable.tf file 

/module/variables.tf
variable "iam-username" {
    description = " username of the iam users" 
    type = list(string)
    default = ["neo","lucy", "rocky"]
}

now lets modify the main.tf file
/iam/main.tf 
 resource "aws_iam_user" "example" {
    count = length(var.iam-username)
    name = var.iam-username[count.index]
 }

 now this will create the 3 user with different name.

suppose we need to outpu the arn of the users. for this we need to create the output.tf file 
/output.tf
output "iam-user-output" {
    decsription = " outputing the arn of the user" 
    value = aws_iam_user.example[0] #0 for the first users
    # select * for all
}

Adding count in resources turns it into the aray of resourcses
and adding count in modules turn it in to array of modules

limitation: 
1. It cannot iterate over inline block inside the resources.
2. When changing the value from between the list, it will delete all the resources after the specific value and create the resources again.


## loops with for_each 

It allows us to loop over the map list sets to create a multiple copies of  resources inline block within a resouces and modules.

syntax
resource "<PROVIDER>_<TYPE>" "<NAME>" {
 for_each = <COLLECTION>
 [CONFIG ...]
}

example: 
resource "aws_iam_user" "example" {
 for_each = toset(var.user_names)
 name = each.value
}

toset: used to conver the list to set as list cannot be used for the resources in for_each 
each.key and each.value is used to acccess the key and value of the current item in the set/map

if we use for_each it will creat a map of resources . 
now if we want to output the particular attribute of the user, we can do by 

output "all_arns" {
 value = values(aws_iam_user.example)[*].arn
}

where values is the builtin funvtion which retunrs just the values form the map and a splat expression. 

 you now have a map of resources with for_each rather than
an array of resources as with count is a big deal, because it allows you to remove items from the middle of a collection safely


Now if we want to delete something from the list of users, it will only destroy the particular resources. 

It can also be used in modules like this: 

module "users" {
 source = "../../../modules/iam/"
 for_each = toset(var.user_names)
 user_name = each.value
}

And you can output the ARNs of those users as follows:
output "user_arns" {
 value = values(module.users)[*].user_arn
 description = "The ARNs of the created IAM users"
}

the other advantage of using for_each is its ability to create multiple inline blocks within a resources. first lets add input variable in variable.tf file. 

/module/variables.tf
variable "custom_tags" {
 description = "Custom tags to set on the Instances"
 type = map(string)
 default = {}
}

Now lets set some tags in our development area: 

module "instance_dev" {
    source = "../modules/ec2

    custom_tags = {
        maintainer = "Nischal"
        Tools = "terraform" 
    }
}

this code sets a coule of useful tags : the maintainer tag specifies who is the maintainer of the code and the tools tag specifies which tools he used. now you have created custom tag but how do you set this on ec2 instance. 

for this lets move on to the ec2.tf file 

resource "aws_instance" "instance-examp" {
    arn = ""
    instance_type = "t2.micro" 

    dynamic "names" { # name that store the result of each iteration
        for_each = var.custom-tags # list/Maps to iterate over
        content {
            key = name.key 
            value = name.value
        }
    }
}

for list we will be using the index number in the place of key and value remains the same

If there are tags that you want to apply to all of your
AWS resources, a more reliable approach is to add the
default_tags block to the aws provider in every one of your
modules:

provider "aws" {
 region = "us-east-2"
 # Tags to apply to all AWS resources by default
 default_tags {
 tags = {
 Owner = "team-foo"
 ManagedBy = "Terraform"
 }
 }
}

 Note: the only exceptions are resources that don’t support tags