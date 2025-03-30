provider "aws" {
  region = "us-east-1"
}

# Get all Availability Zones
data "aws_availability_zones" "available" {}

# Create VPC
resource "aws_vpc" "TASK12" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Task-12-VPC"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "TASK12_IGW" {
  vpc_id = aws_vpc.TASK12.id

  tags = {
    Name = "TASK12-IGW"
  }
}

# Create subnets in 3 AZs
resource "aws_subnet" "subnets" {
  count             = 3
  vpc_id            = aws_vpc.TASK12.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "subnet-${element(["a", "b", "c"], count.index)}"
  }
}

# Create Route Table
resource "aws_route_table" "TASK12_RT" {
  vpc_id = aws_vpc.TASK12.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TASK12_IGW.id
  }

  tags = {
    Name = "TASK12-RT"
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "assoc" {
  count          = 3
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.TASK12_RT.id
}

# Security Group
resource "aws_security_group" "TASK12_SG" {
  name        = "TASK12-SECURITYGROUP"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.TASK12.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TASK12-SG"
  }
}

# Create EC2 Instances in 3 AZs
resource "aws_instance" "servers" {
  count         = 3
  ami           = "ami-071226ecf16aa7d96" 
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnets[count.index].id
  vpc_security_group_ids = [aws_security_group.TASK12_SG.id]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  associate_public_ip_address = true

  tags = {
    Name = "server1${element(["a", "b", "c"], count.index)}"
  }
}
