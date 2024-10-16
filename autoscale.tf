resource "aws_security_group" "inst_security" {
    name = "autoscale_security"
     # inbound flow 
    ingress = {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"

        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

# it is jus the launch configuration for the auto scalling group
# it is used to define the configuration for launching the ec2 instance in a auto scalling group
resource "aws_launch_configuration" "launching_config" { # this create the auto scalling group fro the e2 instance 
    image_id = "ami-0c6d358ee9e264ff1" # instead of ami 
    instance_type = "t2.micro" 

    security_groups = [aws_security_group.inst_security.id]  # adding security group 
    
    # required syntax when using the launch configuration with autoscalling group 
    lifecycle {
        create_before_destroy = true
        # Ensures the launch configuration is created before an old one is destroyed
    }
}
# using the default virtual private cloud 
data "aws_vpc" "vpc_example" {
    default = true # only need this so that it will look up for default vpc in the account
}

#combining this with the subnets 
# Subnets belonging to this VPC are fetched to allow EC2 instances to be launched within the appropriate network environment.
data "aws_subnets" "subnet_example" { 
    filter {
        name = "vpc_id" 
        values = [data.aws_vpc.vpc_example.id] # refering to the vpc 
        # This data source retrieves all subnets associated with the default VPC.
    }

}

resource "aws_autoscalling_group" "autogroup" {
    launch_configuration = aws_launch_configuration.launching_config.id # uses the launch configuration 
    vpc_zone_identifier = data.aws_subnets.subnet_example.ids # assign the subnet for the auto scalling group

    target_group_arns = [aws_lb_target_group.lb_targetgroup.arn] #Attach instances to the Load Balancer target group
    health_check_type = "ELB"
      # it instruct the target group to check the health status of the instances ( if it is healthy and auto replace instance if the instace is unable to respond)


    min_size = 2 # Minimum number of instances
    max_size = 5 # Maximun number of instances

    tag = {
        key = "name"
        value = "terrafrom_autoscalling_example"
        propagate_at_launch = true # Tags will be applied to instances at launch
    }


}
####### Load BALANCER #############

resource "aws_lb" "example_lb" {
    name = "loadbalancer_example"
    load_balancer_type = "application"
    subnets = data.aws_subnets.subnet_example.ids
    security_groups = [aws_security_group.lb_securitygroup.id] # attaching security group to the load balancer
}

# security group just for load balancer 
resource "aws_security_group" "lb_securitygroup" {
    name = "security_for_lb"

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
### load balacer listener 
## Listens for incoming HTTP requests and defines how the Load Balancer should handle them.
resource "aws_lb_listener" "listener_example" {
    load_balancer_arn = aws_lb.example_lb.arn # Attach listener to the ALB
    port = 80 # Listen on HTTP port 80
    protocol = "HTTP"

    default_action {
        type = "fixed-response"
        #simple 404 page as the default response for requests that don’t match any listener rules.
        fixed_response {
            content_type = "text/plain"
            message_body = "404 : page not found"
            status_code = 404
        }
    }

}

# load balancer listener rules 
# Defines a rule that forwards all requests (matching any path) to the Auto Scaling Group target group.
resource "aws_lb_listener_rule" "lb_listenerrules" {
    listener_arn = aws_lb_listener.listener_example.arn # attaching the listener
    priority = 100 # Rule priority

# sends requests that match any path to the target group that contains your ASG.
    condition {
      path_pattern {
        values = ["*"]
      }
    }

    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.lb_targetgroup.arn  # Forward traffic to the target group
    }
  
}

## target group for the load balacer and auto scalling group 
## The target group associated with the load balancer and Auto Scaling Group. It monitors the health of instances.

resource "aws_lb_target_group" "lb_targetgroup" {
    name = "terraform-lb-targetgroup"
    port = 80 
    protocol = "HTTP"
    vpc_id = [data.aws_vpc.vpc_example.id] # Attach to the VPC

    health_check {
      path = "/"
      protocol = "HTTP"
      matcher = "200" # Expect HTTP 200 status code
      interval = 15 # Health check interval
      timeout = 3
      healthy_threshold = 2
      unhealthy_threshold = 2
    }  
}

#output namae
output "dnsname" {
    description = "this will output the dns url which i can used "
    value = aws_instance.machine.machine.dnsname
  
}