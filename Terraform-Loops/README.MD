# Loops, If Statements, Zero Downtime Deployment & Terraform Gotchas

## Loops
Terraform offers several looping constructs, each intended for different scenarios to simplify and scale infrastructure configurations. Below are the main types of loops Terraform provides:

1. **Count**: Used to loop over resources and modules.
2. **for_each**: Used to loop over resources, inline blocks within a resource, and modules.
3. **for**: Used to loop over lists and maps.
4. **for string**: Used to loop over lists and maps within a string.

---

### Loops with `Count`
The `count` parameter allows you to loop over resources or modules, enabling easy scaling of resources.

#### Example: Creating Multiple IAM Users

- **Scenario**: Creating multiple IAM users.
- **Problem**: If we use `count` without modifications, all users will have the same name.

**Code**
```hcl
/iam/main.tf
resource "aws_iam_user" "example" {
    count = 3
    name  = "neo"
}
```
This creates 3 users named `neo`, which is not ideal. 

#### Using `count.index` to Differentiate User Names
To assign unique names, use `count.index`.

**Updated Code**
```hcl
/iam/main.tf
resource "aws_iam_user" "example" {
    count = 3
    name  = "neo.${count.index}"
}
```
This will create users with names like `neo.0`, `neo.1`, and `neo.2`.

#### Using Variables for Custom Names
To avoid hardcoding, define a variable for user names.

**Variables File**
```hcl
/module/variables.tf
variable "iam-username" {
    description = "Username of the IAM users"
    type        = list(string)
    default     = ["neo", "lucy", "rocky"]
}
```

**Updated Code**
```hcl
/iam/main.tf
resource "aws_iam_user" "example" {
    count = length(var.iam-username)
    name  = var.iam-username[count.index]
}
```
This creates users with names from the variable list, such as `neo`, `lucy`, and `rocky`.

#### Outputting User ARNs
Use an `output.tf` file to output specific user attributes.

**Output Code**
```hcl
/output.tf
output "iam-user-output" {
    description = "Outputting the ARN of the user"
    value       = aws_iam_user.example[0] # Outputs the first user's ARN
    # Use [*] to select all ARNs
}
```

#### Notes and Limitations
- Adding `count` to resources turns them into an array.
- Adding `count` to modules turns them into an array of modules.
- **Limitations**:
  1. `count` cannot iterate over inline blocks within resources.
  2. Changing a value in the middle of a list deletes and recreates subsequent resources.

---

### Loops with `for_each`
`for_each` is more flexible than `count` as it works with maps, sets, and lists to create multiple resources or inline blocks within resources.

#### Example: Creating Multiple IAM Users
- **Scenario**: Looping over a set of usernames to create IAM users.

**Code**
```hcl
resource "aws_iam_user" "example" {
    for_each = toset(var.user_names)
    name     = each.value
}
```
- **Key Points**:
  - `toset` converts a list to a set because lists cannot be used with `for_each`.
  - `each.key` and `each.value` access the current item's key and value.

#### Outputting Attributes
To output all user ARNs:
```hcl
output "all_arns" {
    value = values(aws_iam_user.example)[*].arn
}
```
- `values` extracts the values from the map created by `for_each`.
- `[*]` is a splat expression to iterate over all values.

#### Deleting Specific Resources
Using `for_each` ensures only specific items are deleted, unlike `count`, which can cause cascading deletions.

#### Using `for_each` in Modules
You can also use `for_each` with modules.

**Code**
```hcl
module "users" {
    source     = "../../../modules/iam/"
    for_each   = toset(var.user_names)
    user_name  = each.value
}
```
To output module results:
```hcl
output "user_arns" {
    value       = values(module.users)[*].user_arn
    description = "The ARNs of the created IAM users"
}
```

#### Inline Blocks with `for_each`
You can also create multiple inline blocks within a resource using `for_each`.

**Example: Setting Tags Dynamically**

1. **Define Input Variables**
```hcl
/module/variables.tf
variable "custom_tags" {
    description = "Custom tags to set on the instances"
    type        = map(string)
    default     = {}
}
```

2. **Set Tags in Module**
```hcl
module "instance_dev" {
    source = "../modules/ec2"
    custom_tags = {
        maintainer = "Nischal"
        tools      = "terraform"
    }
}
```

3. **Iterate Over Tags in Resource**
```hcl
resource "aws_instance" "instance-examp" {
    arn            = ""
    instance_type  = "t2.micro"

    dynamic "names" {
        for_each = var.custom_tags
        content {
            key   = names.key
            value = names.value
        }
    }
}
```
- **Key Points**:
  - `dynamic` creates inline blocks dynamically.
  - `names.key` and `names.value` access tag keys and values.

#### Global Tags
For tags applied to all resources, use the `default_tags` block in the AWS provider:

**Code**
```hcl
provider "aws" {
    region = "us-east-2"

    default_tags {
        tags = {
            Owner     = "team-foo"
            ManagedBy = "Terraform"
        }
    }
}
```
- Resources that don’t support tags are exceptions.

---

## If Statements

Terraform's `if` statements allow conditional expressions to configure resources dynamically.

**Syntax**:
```hcl
condition ? true_value : false_value
```

**Example**:
```hcl
resource "aws_instance" "example" {
    instance_type = var.is_prod ? "t3.large" : "t3.micro"
}
```
- If `var.is_prod` is `true`, the instance type is `t3.large`.
- Otherwise, it is `t3.micro`.

---

## Zero Downtime Deployment
Zero Downtime Deployment ensures that updates to infrastructure do not cause interruptions. Here’s a common approach:

1. **Use an ALB**:
   - Attach your EC2 instances to an ALB.
   - Gradually shift traffic from old instances to new ones.

2. **Use Terraform Modules**:
   - Split infrastructure into modules.
   - Update modules without affecting others.

3. **Blue-Green Deployment**:
   - Create two identical environments (blue and green).
   - Switch traffic between them.

4. **Rolling Updates**:
   - Use Auto Scaling Groups with `min_size` and `max_size` settings.
   - Gradually replace instances.

---

## Terraform Gotchas
### 1. File Paths
- **Issue**: Paths must be relative to the root module.
- **Solution**: Use the `path.module` variable to ensure paths are relative to the current module.

**Example**:
```hcl
resource "local_file" "example" {
    filename = "${path.module}/example-output.txt"
    content  = file("${path.module}/example.txt")
}
```

### 2. Inline Blocks
- **Issue**: Do not mix inline blocks and separate resource blocks; configurations may override each other.

**Example**:
```hcl
resource "aws_security_group" "alb" {
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
```

### 3. Module Versioning
- **Use Case**: Ensure a specific version of a module is used in your configuration.

**Example**:
```hcl
module "my_module" {
    source  = "git::https://github.com/example/repo.git?ref=v1.0.0"
    version = "~> 1.0"
}
```
