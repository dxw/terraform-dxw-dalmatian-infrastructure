resource "aws_instance" "infrastructure_bastion" {
  count = local.enable_infrastructure_bastion_host ? 1 : 0

  ami                    = data.aws_ami.bastion_ami[0].id
  instance_type          = "t3.micro"
  subnet_id              = local.infrastructure_vpc_network_enable_private ? [for subnet in aws_subnet.infrastructure_private : subnet.id][0] : local.infrastructure_vpc_network_enable_public ? [for subnet in aws_subnet.infrastructure_public : subnet.id][0] : null
  user_data_base64       = base64encode(templatefile("${path.root}/ec2-userdata/bastion.tpl", {}))
  vpc_security_group_ids = [aws_security_group.infrastructure_ec2_bastion_host[0].id]

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "${local.resource_prefix}-infrastructure-bastion"
  }
}
