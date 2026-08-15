# modules/compute/main.tf
# Main config file for the compute module.


### ------------------------
### --- MAIN CLOUD INFRA ---
### ------------------------


resource "aws_instance" "mcp_ec2_instance" {
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = var.instance_type
  user_data              = file("${path.module}/scripts/user_data.sh")
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id

  tags = {
    Name = "MCP Instance"
  }
}

resource "aws_ebs_volume" "mcp_ebs_volume" {
  availability_zone = aws_instance.mcp_ec2_instance.availability_zone
  size              = var.ebs_volume_size
  type              = "gp3"

  tags = {
    Name = "MCP EBS Volume"
  }
}


### -----------------------------
### --- AUXILIARY CLOUD INFRA ---
### -----------------------------


data "aws_ami" "ubuntu_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical (company maintaining Ubuntu images)
}

resource "aws_volume_attachment" "mcp_volume_instance_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.mcp_ebs_volume.id
  instance_id = aws_instance.mcp_ec2_instance.id
}

