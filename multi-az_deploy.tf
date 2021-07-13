provider "aws" {
  region = "eu-west-3" ## region assinged
}

variable "vpc_id"{
  default = "vpc-0962306e2fdfba6f6" ## vpc-id

}

## az1 subnet variable
variable "pa_az1_mgt_subnet_id"{
  default = "subnet-017cd50a3e10f7fb7"
}

variable "pa_az1_public_subnet_id"{
  default = "subnet-0ca166ef748fc9cd0"
}

variable "pa_az1_private_subnet_id"{
  default = "subnet-039b22202c5845b4b"
}

## az2 subnet variable
variable "pa_az2_mgt_subnet_id"{
  default = "subnet-0e53da0e3ed45a868"
}

variable "pa_az2_public_subnet_id"{
  default = "subnet-034eac93d5765daea"
}

variable "pa_az2_private_subnet_id"{
  default = "subnet-0a222dedfdc032f30"
}



## security group
resource "aws_security_group" "allow-mgt-sg" {
  name        = "allow-pa-mgt-sg"
  description = "Allow pa-sg inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "allow-443"
    from_port        = 0
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "allow-22"
    from_port        = 0
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-pa-sg"
  }
}

resource "aws_security_group" "allow-pa-traffic-sg" {
  name        = "allow-pa-traffic-sg"
  description = "Allow pa-sg inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "allow-pa-traffic-sg"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-pa-sg"
  }
}

## EIP mapping
resource "aws_eip" "pa1-mgt" {
  network_interface = aws_network_interface.pa-az1-mgt.id

  tags = {
    Name = "PA1-MGT-EIP"
  }
}

resource "aws_eip" "pa1-untrust" {
  network_interface = aws_network_interface.pa-az1-untrust.id

  tags = {
    Name = "PA1-Untrust-EIP"
  }
}


resource "aws_eip" "pa2-mgt" {
  network_interface = aws_network_interface.pa-az2-mgt.id

  tags = {
    Name = "PA2-MGT-EIP"
  }
}

resource "aws_eip" "pa2-untrust" {
  network_interface = aws_network_interface.pa-az2-untrust.id

  tags = {
    Name = "PA2-Untrust-EIP"
  }
}

## network interface
resource "aws_network_interface" "pa-az1-mgt" {
  subnet_id       = var.pa_az1_mgt_subnet_id
  security_groups = [aws_security_group.allow-mgt-sg.id]

  tags = {
    Name = "PA-AZ1-MGT"
  }
}

resource "aws_network_interface" "pa-az1-untrust" {
  subnet_id       = var.pa_az1_public_subnet_id
  security_groups = [aws_security_group.allow-pa-traffic-sg.id]
  source_dest_check = false

  tags = {
    Name = "PA-AZ1-Untrust"
  }
}

resource "aws_network_interface" "pa-az1-trust" {
  subnet_id       = var.pa_az1_private_subnet_id
  security_groups = [aws_security_group.allow-pa-traffic-sg.id]
  source_dest_check = false


  tags = {
    Name = "PA-AZ1-Trust"
  }

}


resource "aws_network_interface" "pa-az2-mgt" {
  subnet_id       = var.pa_az2_mgt_subnet_id
  security_groups = [aws_security_group.allow-mgt-sg.id]

  tags = {
    Name = "PA-AZ2-MGT"
  }
}

resource "aws_network_interface" "pa-az2-untrust" {
  subnet_id       = var.pa_az2_public_subnet_id
  security_groups = [aws_security_group.allow-pa-traffic-sg.id]
  source_dest_check = false

  tags = {
    Name = "PA-AZ2-Untrust"
  }
}

resource "aws_network_interface" "pa-az2-trust" {
  subnet_id       = var.pa_az2_private_subnet_id
  security_groups = [aws_security_group.allow-pa-traffic-sg.id]
  source_dest_check = false

  tags = {
    Name = "PA-AZ2-Trust"
  }

}




## instance
resource "aws_instance" "az1_paloalto" {
  ami = "ami-01f2432190130a2c6" ## Pan-OS intall version ami-id
  instance_type = "c5.xlarge" ## install instace type
  key_name = "aws_paris_key" ## key pair
  availability_zone = "eu-west-3a" ## AZ
  user_data = "mgmt-interface-swap=enable" ## swap interface

  network_interface {
    network_interface_id = aws_network_interface.pa-az1-mgt.id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.pa-az1-untrust.id
    device_index         = 0
  }

 network_interface {
    network_interface_id = aws_network_interface.pa-az1-trust.id
    device_index         = 2
  }

  root_block_device {
    volume_size = 60

  }

  tags = {
    Name = "Paloalto_AZ1"
  }
}

resource "aws_instance" "az2_paloalto" {
  ami = "ami-01f2432190130a2c6"
  instance_type = "c5.xlarge"
  key_name = "aws_paris_key"
  availability_zone = "eu-west-3b"
  user_data = "mgmt-interface-swap=enable"

    network_interface {
    network_interface_id = aws_network_interface.pa-az2-mgt.id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.pa-az2-untrust.id
    device_index         = 0
  }

 network_interface {
    network_interface_id = aws_network_interface.pa-az2-trust.id
    device_index         = 2
  }


  root_block_device {
    volume_size = 60

  }

  tags = {
    Name = "Paloalto_AZ2"
  }

}

## Cloud9 에 폴더 생성 후 해당 파일을 업로드
## cd /folder 에서 terraform init
## tp plan <filename>.tf 로 해당 tf file에 대한 적합성 검사
## tf apply -auto-approved <filename>.tf 로 Deploy

}

