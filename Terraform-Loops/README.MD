# Loops, If Statements, Zero Downtime Deployment & Terraform Gotchas

## Loops
Terraform offers several looping constructs, each intended for different scenarios to simplify and scale infrastructure configurations. Below are the main types of loops Terraform provides:

1. **Count**: Used to loop over resources and modules.
2. **for_each**: Used to loop over resources, inline blocks within a resource, and modules.
3. **for**: Used to loop over lists and maps.
4. **for string**: Used to loop over lists and maps within a string.
5. **Conditionals**

---

## Loops with `Count`
The `count` parameter allows you to loop over resources or modules, enabling easy scaling of resources.

### Example: Creating Multiple IAM Users

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

### Using `count.index` to Differentiate User Names
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

### Using Variables for Custom Names
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

### Outputting User ARNs
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
**Notes and Limitation:**
- Adding `count` to resources turns them into an array.
- Adding `count` to modules turns them into an array of modules.

- **Limitations**:
  1. `count` cannot iterate over inline blocks within resources.
  2. Changing a value in the middle of a list deletes and recreates subsequent resources.

---

## Loops with `for_each`
`for_each` is more flexible than `count` as it works with maps, sets, and lists to create multiple resources or inline blocks within resources.

### Example: Creating Multiple IAM Users
- **Scenario**: Looping over a set of usernames to create IAM users.

**Code**
```hcl
resource "aws_iam_user" "example" {
    for_each = toset(var.user_names)
    name     = each.value
}
```
- **Key Points**:
  - `toset` converts a list to a set because lists cannot be used with `for_each` with the resources.
  - `each.key` and `each.value` access the current item's key and value.

### Outputting Attributes
To output all user ARNs:
```hcl
output "all_arns" {
    value = values(aws_iam_user.example)[*].arn
}
```
- `values` extracts the values from the map created by `for_each`.
- `[*]` is a splat expression to iterate over all values.

### Deleting Specific Resources
Using `for_each` ensures only specific items are deleted, unlike `count`, which can cause cascading deletions.
Therefore, you should always prefer using `for_each` instead of `count` while creating multiple copies of resources.

### Using `for_each` in Modules
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

### Inline Blocks with `for_each`
You can also create multiple inline blocks within a resource using `for_each`.

**Example: Setting Tags Dynamically**

1. **Define Input Variables**
create a variable.tf file .
```hcl
/module/variables.tf
variable "custom_tags" {
    description = "Custom tags to set on the instances"
    type        = map(string)
    default     = {}
}
```

2. **Set Tags in Module**
we can make a module where we will import the tags to be used. we want our tag to be used on EC2 so we are going to import that specfic module which will point towards EC2.
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
so we have specified what tags we want, now how do we implement in EC2, we can do by this way.
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

### Global Tags
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

## `for` Expression in Terraform

The `for` expression in Terraform is a powerful feature that allows you to loop over lists or maps to set variables or parameters. This document demonstrates how to use `for` expressions to process lists and maps and explains their syntax and usage.

### Looping Over a List

#### Example: Converting List Items to Uppercase
If you have a list of names and you want to output the names in uppercase, you can use the `for` expression as follows:

```hcl
variable "forlist" {
    description = "list of names"
    type        = list(string)
    default     = ["name1", "name2", "name3"]
}

output "uppernames" {
    description = "upper case names"
    value       = [for name in var.forlist : upper(name)]
}
```

**Explanation:**
- The variable `forlist` defines a list of strings.
- The `for` expression `[for name in var.forlist : upper(name)]` iterates over each name in the list and applies the `upper()` function to convert it to uppercase.
- The output will be a list of uppercase names, e.g., `["NAME1", "NAME2", "NAME3"]`.

### Looping Over a Map

#### Example: Outputting Key-Value Pairs in a Map
If you have a map and want to output key-value pairs, you can use the `for` expression as follows:

```hcl
variable "formap" {
    description = "map of names"
    type        = map(string)
    default     = {
        name1 = "name1"
        name2 = "name2"
        name3 = "name3"
    }
}

output "mapnames" {
    description = "map names"
    value       = { for key, value in var.formap : key => "${key} and the value is ${value}" }
}
```
**Explanation:**
- The variable `formap` defines a map of key-value pairs.
- The `for` expression `{ for key, value in var.formap : key => "${key} and the value is ${value}" }` iterates over each key-value pair in the map.
- It creates a new map where the value is a sentence describing the key and its corresponding value.
- The output will look like this:
  ```json
  {
    "name1": "name1 and the value is name1",
    "name2": "name2 and the value is name2",
    "name3": "name3 and the value is name3"
  }
  ```

### Converting a List to a Map

#### Example: Mapping List Items to Keys
You can convert a list into a map using a `for` expression:

```hcl
output "mapnames" {
    description = "outputting the values of list in map"
    value       = { for key, value in var.forlist : key => value }
}
```
**Explanation:**
- The `for` expression `{ for key, value in var.forlist : key => value }` converts the list into a map.
- Each list item becomes a value in the map, with the key being the index or some other derived key if specified.

**Key Differences Between List and Map Syntax:**
- **List Syntax:** Uses square brackets (`[]`) to define and output lists.
- **Map Syntax:** Uses curly braces (`{}`) to define and output maps.

By understanding these basic examples and differences, you can leverage `for` expressions in Terraform to manipulate data structures effectively.
---

## Using `for` String Directives in Terraform

String directives in Terraform allow you to incorporate control statements directly into strings. This feature uses syntax similar to string interpolation but with `%{}` instead of `${}`.

Terraform supports two types of string directives:
1. `for` loops
2. Conditional statements

This document focuses on using `for` loops within string directives.

### Syntax for `for` Loop in String Directives

The syntax for a `for` loop in string directives is as follows:

```hcl
"%{for <item> in <list>} ${item} %{end for}"
```

**Example:**

```hcl
output "for_directives" {
    value = "%{for item in list} ${item}, %{end for}"
}
```

**Explaination:**
- **`item`**: A name assigned to each element of the list during the iteration.
- **`list`**: The list of items you want to loop through.
- **`${item}`**: The expression you want to evaluate or output for each iteration.
- **`%{for <item> in <list>} ... %{end for}`**: Encloses the loop logic.

**Output:**
If `list = ["apple", "banana", "cherry"]`, the result will be:
```text
for_directives = "apple, banana, cherry, "
```

### Using Indexing in `for` String Directives

You can also include the index of each item in the loop using the following syntax:

```hcl
"%{for <index>, <item> in <list>} ${index}${item} %{end for}"
```
**Expample:**

```hcl
output "for_directives_with_index" {
    value = "%{for index, item in list} ${index}: ${item}, %{end for}"
}
```

**Explanation:**
- **`index`**: The position of the item in the list (starting at 0).
- **`item`**: The value at the corresponding position in the list.
- **`${index}${item}`**: Combines the index and the item into a single output.

**Output:**
If `list = ["apple", "banana", "cherry"]`, the result will be:
```text
for_directives_with_index = "0: apple, 1: banana, 2: cherry, "
```

**Key Notes:**
- String directives use `%{}` for control statements, unlike the usual `${}` for string interpolation.
- Always terminate a `for` loop with `%{end for}`.
- The output will be a single string with all evaluated expressions concatenated.

---

## Conditionals in String Directives

String directives in Terraform also support conditional logic, allowing you to implement `if/else` statements within your configurations. This capability is particularly useful for creating dynamic resources based on input variables.

### Example: Using `if/else` Statements for IAM Policies

**Scenario:**
- You want to attach different IAM policies to users based on a boolean variable.
  - If the value is `true`, the user receives an **instance creation access** policy.
  - If the value is `false`, the user receives a **read-only access** policy.

**Input Variables:**
```hcl
variable "uservalue" {
    description = "usernames"
    type = list(string)
    default = ["user1", "user2"]
}

variable "user" {
    description = "user policy assignment toggle"
    type = bool
    default = false
}
```
**Resources:**
```hcl
resource "aws_iam_user_policy_attachment" "user_policy" {
    count      = var.user ? 1 : 0
    user       = aws_iam_user.user[0].name
    policy_arn = aws_iam_policy.instance_create.arn
}

resource "aws_iam_user_policy_attachment" "user_policy" {
    count      = var.user ? 0 : 1
    user       = aws_iam_user.user[1].name
    policy_arn = aws_iam_policy.read_only.arn
}
```

**Explanation:**
- **Resource 1**: Created if `var.user = true`. Attaches the **instance_create** policy to `user1`.
- **Resource 2**: Created if `var.user = false`. Attaches the **read_only** policy to `user2`.
- The `count` parameter ensures only one resource is created depending on the value of `var.user`.

**Output: User and Policy Details:**
To retrieve the policy ARN applied to the user, use the following output:

```hcl
output "userpolicyDetails" {
    value = one(concat(aws_iam_user_policy_attachment.user_policy[*].policy_arn))
}
```
**Explanation:**
- **`concat()`**:
  - Combines the policy ARNs from both resources into a single list.
  - If only one resource is created, that ARN will be the only element in the list.

- **`one()`**:
  - Extracts the first element from the concatenated list.
  - Ensures that only the ARN of the applied policy is returned.

#### Conditional Behavior:
1. **If `var.user = true`**:
   - The first `aws_iam_user_policy_attachment.user_policy` block is created.
   - The `instance_create` policy ARN is included in the output.

2. **If `var.user = false`**:
   - The second `aws_iam_user_policy_attachment.user_policy` block is created.
   - The `read_only` policy ARN is included in the output.

#### Output Example:
- **When `var.user = true`**:
  ```text
  userpolicyDetails = "arn:aws:iam::123456789012:policy/instance_create"
  ```
- **When `var.user = false`**:
  ```text
  userpolicyDetails = "arn:aws:iam::123456789012:policy/read_only"
  ```
**Key Notes:**
- **Dynamic Resource Creation**:
  - Use the `count` parameter with conditional logic to control resource creation.

- **Output Processing**:
  - The combination of `concat()` and `one()` ensures a clean output regardless of which resource is created.

---

## Conditionals with `for_each` and `for` Expression in Terraform

Terraform's `for_each` and `for` expressions provide powerful ways to loop over collections and dynamically create resources or inline blocks. Here's a detailed explanation of how they work, including examples.

### Using `for_each` with `for` Expression

The `for_each` expression is used to iterate over a collection. If the collection is empty, no resources will be created. Conversely, if the collection contains items, Terraform creates a block for each item.

#### Example 1: Basic Usage of `for_each`

```hcl
variable "custom_tags" {
    description = "Custom tags for resources"
    type        = map(string)
    default     = {}
}

dynamic "names" {
    for_each = var.custom_tags
    content {
        key   = names.key
        value = names.value
    }
}
```

**Explanation:**
- The `for_each` loops over `var.custom_tags`.
- If `var.custom_tags` is empty, no resources will be created.
- If `var.custom_tags` contains items, Terraform creates a block for each key-value pair.

#### Example 2: Adding Conditions to `for_each`

To add more control, you can combine `for_each` with a `for` expression and conditions.

```hcl
dynamic "names" {
    for_each = {
        for key, value in var.custom_tags : key => upper(value)
        if key != "Name"
    }
    content {
        key   = names.key
        value = names.value
    }
}
```

**Explanation:**
- The `for` expression loops over `var.custom_tags` and applies the condition `if key != "Name"`.
- Only key-value pairs where the key is not "Name" are included in the iteration.
- The value is converted to uppercase using the `upper()` function.

**Advantages of `for_each` over `count`**
- **Granularity:** `for_each` allows fine-grained control, making it easier to work with complex conditions and collections.
- **Flexibility:** You can use conditions directly within the `for_each` block, providing more dynamic behavior.
- **Inline Blocks:** Perfect for creating dynamic inline blocks or configurations.

---

## Conditionals with String Directives

Terraform also supports conditionals within string directives for more control over outputs or configurations.

### Example: `if` Statement in String Directives

```hcl
output "if_directives" {
    value = <<EOF
    "%{~ for i, name in var.forlist ~} ${name} 
    %{if i < length(var.forlist) - 1}, %{else}.%{ endif } 
    %{~ endfor ~}"
    EOF
}
```

**Explanation:**
- `<<EOF` and `EOF` denote a multi-line string.
- The `~` removes unnecessary whitespace from the string.
- The `for` loop iterates over `var.forlist`.
- The `if` directive checks if the current index is less than the last index of the list.
  - Adds a comma if the condition is true.
  - Adds a period (`.`) if the condition is false.

**Notes:**
- **Multiline Strings:** Use `<<EOF ... EOF` for cleaner, multi-line string outputs.
- **Whitespace Control:** Use `~` to remove extra spaces, ensuring cleaner output.

By leveraging these techniques, you can create dynamic and conditional Terraform configurations with greater precision and readability.

---

## Zero Downtime Deployment in Terraform

Zero downtime deployment is a strategy used in software and infrastructure updates to ensure that services remain available and operational during the deployment process. Terraform supports zero downtime deployment techniques through its declarative infrastructure management and features like resource replacement and updates.

### Key Concepts of Zero Downtime Deployment

**Blue-Green Deployment:**
Blue-Green deployment involves having two identical environments: one (blue) currently serving traffic and another (green) being prepared with the new changes. Once the green environment is fully tested and ready, traffic is switched to it. This ensures minimal disruption, as the old environment (blue) is still available for rollback if needed.

**Rolling updates:**
Rolling updates gradually replace old instances of a service with new ones, ensuring that a minimum number of instances are always available. This approach is particularly useful in environments like Kubernetes or auto-scaling groups where services are scaled across multiple instances.

**Terraform’s Role:**
Terraform can orchestrate these deployment strategies by managing infrastructure and automating resource updates. Its ability to create and destroy resources incrementally allows for seamless transitions.

**Dependency Management:**
Terraform manages dependencies between resources to ensure that updates occur in the correct order. This is critical during deployments to avoid disruptions caused by improper sequencing of resource updates.

**Immutable Infrastructure:**
Terraform supports immutable infrastructure, where instead of modifying existing resources, new ones are created with the desired state. Once the new resources are validated, the old ones are decommissioned. This approach minimizes the risk of deployment errors.

**Canary Deployments:**
Canary deployments involve deploying updates to a small subset of the environment first to verify their stability before rolling them out to the entire system. This allows for early detection of issues without impacting all users.

**Use of Load Balancers:**
Load balancers play a crucial role in zero downtime deployment. Terraform can configure load balancers to route traffic dynamically, ensuring that only healthy and updated resources receive traffic.

**Monitoring and Rollbac:**
Terraform's integrations with monitoring tools allow for real-time observation of the deployment process. In case of failures, rollback mechanisms can be implemented to revert to a stable state using Terraform's state management.

**Challenges:**
Zero downtime deployment requires careful planning, including defining health checks, managing state, and testing transitions. Ensuring compatibility between old and new versions is also crucial to avoid service interruptions.

---

These are the widely used loops in Terraform.
