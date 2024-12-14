# Loops, If Statement, Zero Downtime Deployment & Terraform Gotchas

## Loops
Terraform offers several different looping constructs, each intended to be used in slightly different scenarios:

1. **count**: To loop over resources and modules.
2. **for_each**: To loop over resources, inline blocks within resources, and modules.
3. **for**: To loop over lists and maps.
4. **for string**: To loop over lists and maps within a string.

### Loops with Count
`count` is used inside the resource block. For example, to create multiple IAM users:

#### Example 1: Basic Count Usage
```hcl
/iam/main.tf
resource "aws_iam_user" "example" {
    count = 3
    name = "neo"
}
```
This creates three users with the same name. To avoid this, use the `count.index`:

```hcl
/iam/main.tf
resource "aws_iam_user" "example" {
    count = 3
    name = "neo.${count.index}"
}
```
This will create users with names `neo.1`, `neo.2`, and `neo.3`. To provide better names, use a variable file:

#### Example 2: Using Variables
```hcl
/module/variables.tf
variable "iam-username" {
    description = "Username of the IAM users"
    type = list(string)
    default = ["neo", "lucy", "rocky"]
}
```

```hcl
/iam/main.tf
resource "aws_iam_user" "example" {
    count = length(var.iam-username)
    name = var.iam-username[count.index]
}
```

#### Outputting Results
To output the ARN of the users:

```hcl
/output.tf
output "iam-user-output" {
    description = "Outputting the ARN of the user"
    value = aws_iam_user.example[0] # 0 for the first user; use `[*]` for all users.
}
```
Adding `count` in resources turns it into an array of resources, and in modules, it creates an array of modules.

#### Limitations:
1. Cannot iterate over inline blocks inside resources.
2. Changing a value in the middle of a list deletes and recreates all subsequent resources.

### Loops with for_each
`for_each` allows us to loop over maps, lists, and sets to create multiple copies of resources, inline blocks, and modules.

#### Syntax
```hcl
resource "<PROVIDER>_<TYPE>" "<NAME>" {
    for_each = <COLLECTION>
    [CONFIG ...]
}
```

#### Example: IAM Users with for_each
```hcl
resource "aws_iam_user" "example" {
    for_each = toset(var.user_names)
    name = each.value
}
```
Here, `toset` converts the list into a set, as lists cannot be directly used in `for_each`. You can access the key and value using `each.key` and `each.value`.

#### Outputting Results
```hcl
output "all_arns" {
    value = values(aws_iam_user.example)[*].arn
}
```
Using `for_each` creates a map of resources, allowing safe removal of items from the middle of a collection.

#### Using for_each with Modules
```hcl
module "users" {
    source = "../../../modules/iam/"
    for_each = toset(var.user_names)
    user_name = each.value
}
```
Output the ARNs:
```hcl
output "user_arns" {
    value = values(module.users)[*].user_arn
    description = "The ARNs of the created IAM users"
}
```

#### Inline Blocks with for_each
To set custom tags on EC2 instances:

```hcl
/module/variables.tf
variable "custom_tags" {
    description = "Custom tags to set on the instances"
    type = map(string)
    default = {}
}
```

Set tags in the development area:
```hcl
module "instance_dev" {
    source = "../modules/ec2"
    custom_tags = {
        maintainer = "Nischal"
        tools      = "Terraform"
    }
}
```

Define the EC2 instance resource:
```hcl
resource "aws_instance" "instance-example" {
    instance_type = "t2.micro"

    dynamic "names" {
        for_each = var.custom_tags
        content {
            key   = names.key
            value = names.value
        }
    }
}
```
If working with lists, use index numbers in place of `key`.

#### Default Tags for AWS Resources
To apply tags across all AWS resources:
```hcl
provider "aws" {
    region = "us-east-2"

    default_tags {
        tags = {
            Owner      = "team-foo"
            ManagedBy  = "Terraform"
        }
    }
}
```
Note: Some resources may not support tags.
