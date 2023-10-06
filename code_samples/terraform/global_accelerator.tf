# Define AWS provider
provider "aws" {
  region = "eu-west-1" # Specify your desired AWS region
}

# Create an AWS Global Accelerator
resource "aws_globalaccelerator_accelerator" "example" {
  name = "example-accelerator"
  ip_address_type = "IPV4" # Use "IPV4" or "IPV6"
}

# Define listeners for the accelerator
resource "aws_globalaccelerator_listener" "example" {
  accelerator_arn = aws_globalaccelerator_accelerator.example.id
  port_ranges {
    from_port = 80
    to_port   = 80
  }
  protocol = "TCP" # Specify the desired protocol
}

# Create an endpoint group for NLBs
resource "aws_globalaccelerator_endpoint_group" "example" {
  listener_arns = [aws_globalaccelerator_listener.example.id]
  endpoint_group_region = "eu-west-1" # Specify the AWS Region
  endpoint_configurations {
    endpoint_id = aws_lb.example.id # Replace with your NLB resource ID
  }
  health_check_port = 80 # Specify the health check port
  health_check_path = "/" # Specify the health check path
}

# Create a Network Load Balancer
resource "aws_lb" "example" {
  name               = "example-nlb"
  internal           = false # Set to true if it's an internal NLB
  load_balancer_type = "network"
  subnets            = ["subnet-1a2b3c4d", "subnet-5e6f7g8h"] # Replace with your subnet IDs
}

# Define NLB target group
resource "aws_lb_target_group" "example" {
  name     = "example-target-group"
  port     = 80
  protocol = "TCP"
  vpc_id   = "your-vpc-id" # Replace with your VPC ID

  stickiness {
    type    = "lb_cookie"
    enabled = false
  }
}

# Attach NLB target group to NLB
resource "aws_lb_target_group_attachment" "example" {
  target_group_arn = aws_lb_target_group.example.arn
  target_id        = aws_instance.example.id # Replace with your target resource ID
}
