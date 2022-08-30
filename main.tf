terraform {
  backend "s3" {
    bucket         = "tfbackendpro"
    key            = "terraform-state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lock_table"
    encrypt        = true
  }
}

module "testvpc_module" {
  source            = "./modules/vpc_module"
  vpc_cidr          = var.test_vpc_cidr
  availability_zone = var.test_az[*]
}

module "testsg_module" {
  source = "./modules/sg_module"
  vpc_id = module.testvpc_module.vpc_id
}

resource "aws_instance" "priv_instance" {
  ami               = var.ami_id
  instance_type     = var.instance_type
  availability_zone = var.test_az[1]
  key_name          = var.key
  root_block_device {
    volume_size = var.root_volume_size
  }
  subnet_id                   = module.testvpc_module.privsubnet_id
  vpc_security_group_ids      = [module.testsg_module.sg_id]
  associate_public_ip_address = false

}
resource "aws_launch_configuration" "testconf" {
  name            = "testlc"
  image_id        = var.ami_id
  instance_type   = var.instance_type
  key_name        = var.key
  security_groups = [module.testsg_module.sg_id]
  root_block_device {
    volume_size = var.root_volume_size
  }
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install stress
              sudo stress --cpu 1 --timeout 500s
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "test_asg" {
  name                 = "testasg"
  launch_configuration = aws_launch_configuration.testconf.name
  min_size             = 3
  desired_capacity     = 3
  max_size             = 6
  vpc_zone_identifier  = [module.testvpc_module.pubsubnet_id]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "testasg_scaleup" {
  autoscaling_group_name = aws_autoscaling_group.test_asg.name
  name                   = "testasgpolicyup"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  policy_type            = "SimpleScaling"
  cooldown               = "30"
}

resource "aws_cloudwatch_metric_alarm" "testasg_scaleup" {
  alarm_name          = "testasg_alarm_upscale"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "30"
  statistic           = "Average"
  threshold           = "75"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.test_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.testasg_scaleup.arn]
}

resource "aws_autoscaling_policy" "testasg_scaledown" {
  autoscaling_group_name = aws_autoscaling_group.test_asg.name
  name                   = "testasgpolicydown"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  policy_type            = "SimpleScaling"
  cooldown               = "30"
}

resource "aws_cloudwatch_metric_alarm" "testasg_scaledown" {
  alarm_name          = "testasg_alarm_downscale"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "30"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.test_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.testasg_scaledown.arn]
}