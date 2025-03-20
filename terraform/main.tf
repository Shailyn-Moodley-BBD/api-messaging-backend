terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    postgresql = {
      source = "cyrilgdn/postgresql"
      version = "~> 1.19.0"
    }
  }

  backend "s3" {
    region  = "af-south-1"
  }
}

provider "aws" {
  region = "af-south-1"
}


provider "postgresql" {
  host            = aws_db_instance.api_messenger_db.address
  port            = 5432
  username        = var.db_username
  password        = var.db_password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}

resource "random_id" "suffix" {
  byte_length = 4
}

data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "available_zones" {}

data "aws_subnet" "subnet_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]
  default_for_az    = true
  vpc_id            = data.aws_vpc.default.id
}

data "aws_subnet" "subnet_az2" {
  availability_zone = data.aws_availability_zones.available_zones.names[1]
  default_for_az    = true
  vpc_id            = data.aws_vpc.default.id
}

data "aws_subnet" "subnet_az3" {
  availability_zone = data.aws_availability_zones.available_zones.names[2]
  default_for_az    = true
  vpc_id            = data.aws_vpc.default.id
}

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name        = "api-messenger-db-subnet-group-${random_id.suffix.hex}"
  description = "Subnet group for the API Messenger database"
  subnet_ids  = [
    data.aws_subnet.subnet_az1.id,
    data.aws_subnet.subnet_az2.id,
    data.aws_subnet.subnet_az3.id
  ]
}

resource "aws_security_group" "db_sg" {
  name        = "api-messenger-db-sg-${random_id.suffix.hex}"
  description = "Security group for API Messenger database"
  vpc_id      = data.aws_vpc.default.id
  
  ingress {
    from_port   = 5432 
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "api_messenger_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "17.4"
  instance_class       = "db.t3.micro"
  identifier           = "api-messenger-db"
  username             = var.db_username
  password             = var.db_password
  skip_final_snapshot  = true
  publicly_accessible  = true
  db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

resource "postgresql_database" "db" {
  name      = var.db_name
  owner     = var.db_username
  
  depends_on = [aws_db_instance.api_messenger_db]
}
