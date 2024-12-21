# Terraform Variables Explained

This README provides a detailed explanation of various types of variables and their usage in Terraform. Variables in Terraform help to make your configurations dynamic and reusable by abstracting values into a separate section of the configuration.

---

## Variable Definitions and Examples

### 1. Basic Variable

```hcl
variable "number_example" {
    description = "This is the practice variable description"
    type        = string # Available types: string, number, bool, list, map, set, object, tuple, and any
    default     = "nischal-variable"
    sensitive   = false  # If true, this variable will not be logged in plan or apply outputs
}
```

#### Explanation:
- **description**: Provides metadata about the variable, making it easier to understand.
- **type**: Specifies the variable type. Here it is `string`.
- **default**: Provides a fallback value if the user does not override this variable.
- **sensitive**: If set to `true`, Terraform hides the value during execution, improving security.

---

### 2. List Variable

```hcl
variable "list_numeric_example" {
    description = "An example of a numeric list in Terraform"
    type        = list(number)
    default     = [1, 2, 3]
}
```

#### Explanation:
- **type**: Defines a list of `number` values.
- **default**: Specifies a default numeric list.

---

### 3. Map Variable

```hcl
variable "map_example" {
    description = "An example of a map in Terraform"
    type        = map(string)
    default     = {
        key1 = "value1"
        key2 = "value2"
        key3 = "value3"
    }
}
```

#### Explanation:
- **type**: Defines a map where all values must be strings.
- **default**: Specifies a key-value mapping of strings.

---

### 4. Object Variable

```hcl
variable "object_example" {
    description = "An example of a structural type in Terraform"
    type        = object({
        name    = string
        age     = number
        tags    = list(string)
        enabled = bool
    })
    default = {
        name    = "value1"
        age     = 42
        tags    = ["a", "b", "c"]
        enabled = true
    }
}
```

#### Explanation:
- **type**: Defines a complex data structure with specific attributes.
    - **name**: A string.
    - **age**: A number.
    - **tags**: A list of strings.
    - **enabled**: A boolean value.
- **default**: Provides a structured default value.

---

## Interpolations in Terraform

To use a reference inside a string literal, you need to use an **interpolation**. The syntax for interpolation is:

```hcl
"${variable_name}"
```

### Example Usage:

```hcl
output "example_output" {
    value = "The value of number_example is: ${var.number_example}"
}
```

---

## Key Points

1. **Variable Types**:
   - Use types such as `string`, `number`, `bool`, `list`, `map`, and `object` to define the structure and constraints of the variables.
2. **Default Values**:
   - Default values make variables optional unless explicitly overridden.
3. **Sensitive Variables**:
   - Use the `sensitive` flag to mask sensitive data during execution.
4. **Complex Structures**:
   - Utilize objects to define advanced configurations.
5. **Dynamic References**:
   - Interpolations help integrate variables dynamically within strings.

By understanding these fundamental concepts, you can write efficient, reusable, and secure Terraform configurations.
