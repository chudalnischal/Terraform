
###### OUTPUT VARIABLES ######

# instead of having to manually poke around the ec2 console to find out the ipaddress of your server
# we can find out by using output variable

output "ip_address_ec2" {
    value = aws_instance.machine.machine.public_ip 
    description = "this will return the public ip address of your instance"
}
#output variable show after running the terraform apply 

# we can use terraform output command to list all the outputs without applying changes
