# Bastion Server
# Only active if operator mode is turned on.  Use this to SSH into 

resource "aws_instance" "bastion" {
  count = var.operator_mode ? 1 : 0

  ami = var.use_lastest_ami ? data.aws_ssm_parameter.latest_ami.value : "ami-0323c3dd2da7fb37d"
  instance_type = "t2.micro"
  key_name = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id = aws_subnet.public[0].id
  associate_public_ip_address = true

  tags = merge(
    { "Name" = "${var.main_project_tag}-bastion"},
    { "Project" = var.main_project_tag }
  )
}
