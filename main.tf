# To define variables
variable "aws_var" {
	type = map
	default = {
	region = "us-east-1"
	vpc = "vpc-0ea6be6012bb9979b"
	ami = "ami-04505e74c0741db8d"
	itype = "t2.micro"
	subnet = "subnet-0b65eb5f738064f3e"
	publicip = true
	keyname = "test_key"
	secgroupname = "TEST-Sec-Group"
  }
}

provider "aws" {
  region = lookup(var.aws_var, "region")
}

# To create define ssh key
resource "tls_private_key" "test-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# To define generate ssh key
resource "aws_key_pair" "generated_key" {
  key_name = lookup(var.aws_var, "keyname")
  public_key = tls_private_key.test-key.public_key_openssh
}

# To save a copy of ssh key to local
resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.generated_key.key_name}.pem"
  content = tls_private_key.test-key.private_key_pem
  file_permission = "0400"
}
  
  
# To create security group
resource "aws_security_group" "test-sg" {
  name = lookup(var.aws_var, "secgroupname")
  description = lookup(var.aws_var, "secgroupname")
  vpc_id = lookup(var.aws_var, "vpc")

  ## To Allow SSH 
  ingress {
	from_port = 22
	protocol = "tcp"
	to_port = 22
	cidr_blocks = ["0.0.0.0/0"]
  }

  ## To Allow Tendermint rpc
  ingress {
	from_port = 26657
	protocol = "tcp"
	to_port = 26657
	cidr_blocks = ["172.31.16.0/24"]
  }

  ## To Allow Cosmos rpc
  ingress {
	from_port = 1317
	protocol = "tcp"
	to_port = 1317
	cidr_blocks = ["172.31.16.0/24"]
  }
  
  ## To outgoing
  egress {
	from_port       = 0
	to_port         = 0
	protocol        = "-1"
	cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
	create_before_destroy = true
  }
}

# To create the blockchain node
resource "aws_instance" "bc_node" {
  ami = lookup(var.aws_var, "ami")
  instance_type = lookup(var.aws_var, "itype")
  subnet_id = lookup(var.aws_var, "subnet")
  private_ip = "172.31.16.200"
  associate_public_ip_address = lookup(var.aws_var, "publicip")
  key_name = aws_key_pair.generated_key.key_name

  vpc_security_group_ids = [
	aws_security_group.test-sg.id
  ]
  root_block_device {
	delete_on_termination = true
	volume_size = 50
	volume_type = "gp2"
  }
  
  user_data = "${file("init.sh")}"
  
  tags = {
	Name ="Blockchain_Node_01"
	Environment = "TEST"
	OS = "UBUNTU"
	
  }

  depends_on = [ aws_security_group.test-sg ]
}

# To create the application node
resource "aws_instance" "app_node" {
  ami = lookup(var.aws_var, "ami")
  instance_type = lookup(var.aws_var, "itype")
  subnet_id = lookup(var.aws_var, "subnet")
  private_ip = "172.31.16.201"
  associate_public_ip_address = lookup(var.aws_var, "publicip")
  key_name = aws_key_pair.generated_key.key_name

  vpc_security_group_ids = [
	aws_security_group.test-sg.id
  ]
  root_block_device {
	delete_on_termination = true
	volume_size = 50
	volume_type = "gp2"
  }
  tags = {
	Name ="Application_Node_01"
	Environment = "TEST"
	OS = "UBUNTU"
	
  }

  depends_on = [ aws_security_group.test-sg ]
}

# To output the pubic IP address
output "blockchain_node_ip" {
  value = aws_instance.bc_node.public_ip
}
output "application_node_ip" {
  value = aws_instance.app_node.public_ip
}