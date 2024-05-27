terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  profile = "default"
  region  = "eu-north-1"
}        

resource "aws_vpc" "mian-Vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc-1"
  }
}

resource "aws_subnet" "public-subnet-1" {
  vpc_id     = aws_vpc.mian-Vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public subnet "
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.mian-Vpc.id

  tags = {
    Name = "Internet Gateway"
  }
}

resource "aws_route_table" "routing-table" {
  vpc_id = aws_vpc.mian-Vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  tags = {
    Name = "Public Route Table"
  }
}
resource "aws_route_table_association" "public-associate-table" {       //assiciation part 
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.routing-table.id
}
resource "aws_security_group" "sec_group" {
  name   = "sec_group"
  vpc_id = aws_vpc.mian-Vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_instance" "testing-ec2" {
  ami           = "ami-03238ca76a3266a07"
  instance_type = "t3.micro"
  key_name      = "MyKeyPair"


  subnet_id                   = aws_subnet.public-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.sec_group.id]
  associate_public_ip_address = true


}

output "instance-public-ip" {
  value = aws_instance.testing-ec2.public_ip
}

resource "aws_ssm_parameter" "storing-pub-ip" {
  name  = "/ec2/publicip"
  type  = "String"
  value = aws_instance.testing-ec2.public_ip
  }

