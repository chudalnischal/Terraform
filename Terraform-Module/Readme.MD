# Understanding Terraform Modules

## Introduction to Terraform Modules

A module in Terraform is a container for multiple resources that are used together. A module can be as simple as a single .tf file or as complex as a folder containing multiple .tf files that define various resources, input/output variables, and additional logic. By organizing resources into modules, you can make configurations reusable, modular, and easy to manage.

## Folder Structure for Learning Modules

Here's an example of how you might structure your folders when learning Terraform modules:

terraform/
├── module/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── example.txt
└── Project/
     └── main.tf


* /module/: This directory contains the reusable module, which has all the configurations for specific resources.

* /Project/: This directory is the root project directory where the module is utilized.

## Why Use Modules?

- **Reusability**: Define resources once and reuse across multiple projects.
- **Organization**: Helps in structuring complex Terraform code into manageable units.
- **Consistency**: Ensures uniform configuration across projects.
- **Simplifies Management**: Changes can be made in one place and reflected globally.



## Creating and Using a Module

### Basic Module Declaration

To use a module, you need to reference it in your main Terraform configuration:

```hcl
module "new_module" {
  source = "./Project" # Specifies the path to the module
}
```

### Problem with Hardcoded Values

Even after initializing your module with the `terraform init` command, if your Project folder has hardcoded names, it can lead to conflicts when using the module multiple times within an account. To avoid this, you should use input variables in your module.

## Using Input Variables

### Defining Input Variables

Add a `variables.tf` file to the folder where you want to import the Terraform module. For example, in `/module/variables.tf`:

```hcl
variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
}
```

### Using the Variable in the Module

To utilize the input variable defined in the `variables.tf` file, reference it in the `main.tf` file within the `/module` folder. This helps in creating resources dynamically based on input values.

Example of `main.tf` in the `/module` folder:

```hcl
# /module/main.tf
resource "aws_security_group" "lb_securitygroup" {
  name = "${var.cluster_name}-security_for_lb" # Dynamic name using input variable

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "-1" # "-1" means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## Module Block with Variables
In your project’s main.tf file, you can reference the module and pass the input variable as shown below:

Example of using the module in /project/main.tf:
```hcl
#/Project/main.tf
module "new_module" {
  source = "./module" # Path to the module
  cluster_name = "staging-cluster"
}
```

### Explanation
- Input Variables: Allow you to pass dynamic values to the module, making it reusable and adaptable for different environments or configurations.
- Resource Creation: The ${var.cluster_name} in main.tf ensures that the aws_security_group name is unique and avoids conflicts when the module is used multiple times.
- Modular Code: The use of modules with variables promotes clean, maintainable, and scalable code structures.

## Module Locals

### What Are Locals?

Locals in Terraform are used to declare values that can be reused within a module. They provide a convenient way to store values that may be referenced multiple times within the same module. Unlike input variables, which can be modified by the user, local values remain constant and cannot be changed from outside the module.

### Why Use Locals?

- **Reusability**: Store values that are used multiple times in a module to avoid duplication.
- **Consistency**: Ensure that the value remains the same across the module and cannot be altered by the user.
- **Clarity**: Make your code easier to read and maintain by giving meaningful names to repeated values.

### Syntax for Declaring Locals

Locals are declared using the `locals` block. Here’s an example that builds upon the previous example of input variables and modules:

```hcl
# /project/main.tf
locals {
    http_port = 80
    any_port = 0 
    tcp_protocol = "tcp" 
}
```

### Using Locals in Resources
After declaring locals, you can use them in resource blocks within the module. This helps make your code more readable and ensures that if a value needs to be updated, you only need to modify it in one place.

Example of using locals in the main.tf file:

```hcl 
# /project/main.tf
resource "aws_security_group" "lb_securitygroup" {
    name = "security_for_lb" # This can be dynamically constructed if needed, e.g., "${var.cluster_name}-security_for_lb"

    # Inbound traffic
    ingress {
        from_port = local.http_port  # Using the local variable for the port
        to_port = local.http_port
        protocol = local.tcp_protocol  # Using the local variable for the protocol
        cidr_blocks = ["0.0.0.0/0"]
    }
}
```

### Explanation
- **Local Variables**: Declared with the locals block and used to store constant values that do not change throughout the module.
- **Reusability**: Using local.http_port and local.tcp_protocol ensures that the port and protocol values are consistent wherever they are used in the module.
- **Code Simplification**: With locals, any change to http_port or tcp_protocol must only be made in one place, promoting code maintainability.
- **User Modification**: Unlike input variables that can be passed by the user when running terraform apply, local variables are immutable and cannot be overridden from outside the module.

###Benefits of Using Locals
-**Avoiding Duplication**: You don't need to repeat the same value across multiple places in your code.
Ease of Updates: To change a value, you only modify it once in the locals block, reflecting it everywhere it's used in the module.
- **Readability**: Local variables can be named meaningfully, making the code more readable and understandable.

## Module Outputs

### What Are Outputs?

Outputs in Terraform are used to return specific information from a module to the user or to other modules. They help expose values, such as resource IDs or attributes, so that they can be used elsewhere in your Terraform configuration or just for informational purposes.

### How to Create Outputs

1. **Defining Outputs in the Module**:
   - First, create an `outputs.tf` file in the module folder and define the output that you want to expose. This step allows the module to provide a specific value back to the calling project.

   ```hcl
   # /module/outputs.tf

   output "s3_bucket_name" {
     value       = aws_s3_bucket.s3store.id  # Outputs the ID (name) of the S3 bucket created
     description = "value of the s3 bucket name"
   }
    ```

### Explanation:
The output block declares an output value called s3_bucket_name.
The value is set to aws_s3_bucket.s3store.id, which will be the ID (name) of the S3 bucket created by the module.
The description provides a brief explanation of what the output represents.
Importing Outputs in the Main Project:

After defining the output in the module, you need to import the output in the main.tf file of the project where the module is being used. This is done using the module.<module_name>.<output_name> syntax.

/project/main.tf 
Syntax to reference an output from a module
`module.newModule.s3_bucket_name`

### Explanation:
`module.newModule.s3_bucket_name` accesses the output s3_bucket_name from the module named newModule in the current project.

### Outputting the Value in the Project:

You can also create an output in the main project to display or use the value of the imported module output.

```hcl
 #/project/main.tf
output "modulebucket_name" {
    value       = module.newModule.s3_bucket_name
    description = "value of the bucket name which is imported from the module folder and outputted"
}
```

## Important Module Gotchas

### 1. File Paths

When working with modules in Terraform, managing file paths correctly is crucial to avoid unexpected issues. The path to a module should be relative to the root module, ensuring that modules can be reused without needing to adjust file paths based on their location.

#### Using the `path.module` Variable

`path.module` is a built-in Terraform variable that points to the directory where the current module is located. This can be helpful to construct file paths that are relative to the module itself, making it easier to read or write files within the module regardless of where the module is called from.

**Example Usage**:
```hcl
# /project/main.tf

resource "local_file" "example" {
  filename = "${path.module}/example-output.txt"  # Output file in the module folder
  content  = file("${path.module}/example.txt")   # Read the local file
}
```

### Explanation:
- **filename** = "${path.module}/example-output.txt": This line specifies the output file path, ensuring it is relative to the module's location.
- **content** = file("${path.module}/example.txt"): This reads the content of the example.txt file from the module directory.

#### Why Use path.module?
- **Consistency**: Using path.module helps maintain consistent file paths that do not depend on where the module is being invoked. This ensures that your configuration will work even when the module is used in different projects or directory structures.
- **Portability**: The module can be moved to different locations or reused in different projects without needing to modify the file paths.

**Final Notes**
Always use path.module when referencing files within a module to avoid path-related errors.
This approach ensures that your code is modular and can be easily shared or relocated while maintaining correct file references.

## 2. Inline Blocks

### What are Inline Blocks?

An **inline block** is an argument you set within a resource, formatted as follows:

```hcl
resource "xxx" "yyy" {
  <NAME> {
    [CONFIG...]
  }
}
```

<NAME> is the name of the inline block.
[CONFIG...] is the configuration for the block.

### Example of Inline Blocks in a Security Group
Inline blocks allow you to define multiple configurations within a single resource. For example, a security group in AWS can have both ingress and egress rules defined within the same resource block.

**Example Code:**

```hcl
# /module/main.tf
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
```
##### Note on Configuration
- Do not mix inline blocks with separate resource blocks in the same resource, as this may override configurations and cause unexpected behavior.

### Example of Separate Resource Blocks
Instead of using inline blocks, you can create separate resource blocks for ingress and egress rules.

**Example Code:**

```hcl
# /module/main.tf
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
```
 ### Adding Extra Configuration in the Project Folder
- When adding additional rules in the project folder that rely on the module, you can do so by referencing the output from the module.

**Example Code:**

```hcl
# /project/main.tf
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
```

### Explanation:
- **Inline Blocks**: All ingress and egress configurations are included within the aws_security_group resource block.
- **Separate Resource Blocks**: aws_security_group_rule resources are used to define ingress and egress rules separately, allowing for more granular control and additional configurations in other parts of your configuration.
- **Extra Configuration**: You can add new rules in the project folder by referencing the output from the module, ensuring that the new rules apply to the security group created within the module.
This approach provides flexibility in structuring and customizing your infrastructure code.

## 3. Module Versioning

### What is Module Versioning?

Module versioning in Terraform allows you to lock specific versions of a module in your configuration. This ensures consistency and predictability when deploying infrastructure, as you are guaranteed to use a known version of a module that hasn't changed unexpectedly.

### Why Use Module Versioning?

- **Consistency**: Ensures that your infrastructure code works as expected without surprises due to unintended updates.
- **Control**: Gives you the ability to update modules intentionally, rather than automatically, which helps in testing and managing changes.
- **Stability**: Reduces the risk of breaking changes affecting your infrastructure.

### Best Practice for Versioning Modules

The best practice for versioning modules is to use a **GitHub repository** for the module and then specify the version in the module block using version constraints.

### How to Version a Module in a GitHub Repository

1. **Tag a version**: In your GitHub repository, you can tag specific versions of your module (e.g., `v1.0.0`).
2. **Specify the version**: In your `main.tf` or wherever you include the module, use the `version` argument to specify the version.

**Example of Using a Versioned Module**:
```hcl
module "example_module" {
  source  = "github.com/username/repo-name//module-folder"
  version = "v1.0.0"  # Specify the version tag from the GitHub repository
}
```
### Explanation:
- source: Specifies the URL to the module's GitHub repository and the path to the specific folder containing the module.
- version: The version tag defined in the GitHub repository (e.g., v1.0.0).

### Benefits of Versioning Your Modules:
- Ensures that your infrastructure code is predictable and deployable without unexpected changes.
- Allows you to control updates and improvements to the module, testing them before they are rolled out to production.
- Using versioned modules provides a more controlled, stable, and reliable infrastructure deployment process.