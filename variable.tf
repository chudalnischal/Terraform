
variable "number_example" {
    description = "this is the practice variable description"
    type = string #string, number, bool, list, map, set, object, tuple, and any 
    default = "nischal-variable"
    sensitive =  false #If you set this parameter to true on an input variable, Terraform will
                       #not log it when you run plan or apply
    }

    variable "list_numeric_example" {
 description = "An example of a numeric list in Terraform"
 type = list(number)
 default = [1, 2, 3]
}
# And here’s a map that requires all of the values to be strings:
variable "map_example" {
   description = "An example of a map in Terraform"
   type = map(string)
   default = {
      key1 = "value1"
      key2 = "value2"
      key3 = "value3"
 }
}
#You can also create more complicated structural types using the object type constraint:
variable "object_example" {
   description = "An example of a structural type in Terraform"
   type = object({
     name = string
     age = number
     tags = list(string)
     enabled = bool
 })
 default = {
   name = "value1"
   age = 42
   tags = ["a", "b", "c"]
   enabled = true
 }
}

#To use a reference inside of a string literal, you need to
#use a new type of expression called an interpolation, which has the
#following syntax:
 #      "${}"



###### OUTPUT VARIABLES

# instead of having to manually poke around the ec2 console to find out the ipaddress of your server
# we can find out by using output variable

output "ip_address_ec2" {
    value = aws_instance.machine.machine.public_ip 
    description = "this will return the public ip address of your instance"
}
#output variable show after running the terraform apply 

# we can use terraform output command to list all the outputs without applying chanegs