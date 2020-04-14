# EC2 Auto Scaling Group

resource "aws_autoscaling_group" "vault-asg" {
  name_prefix = "${var.main_project_tag}-asg-"

  launch_template {
    id = aws_launch_template.vault_instance.id
    version = aws_launch_template.vault_instance.latest_version
  }

  target_group_arns = [aws_lb_target_group.alb_targets.arn]

  # All the same to keep at a fixed size
  desired_capacity = var.vault_instance_count
  min_size = var.vault_instance_count
  max_size = var.vault_instance_count

  # AKA the subnets to launch resources in 
  vpc_zone_identifier = aws_subnet.private.*.id

  health_check_grace_period = 300
  health_check_type = "EC2"
  termination_policies = ["OldestLaunchTemplate"]
  wait_for_capacity_timeout = 0

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances"
  ]

  tags = [
    {
      key = "Name"
      value = "${var.main_project_tag}-instance"
      propagate_at_launch = true
    },
    {
      key = "Project"
      value = var.main_project_tag
      propagate_at_launch = true
    }
  ]
}