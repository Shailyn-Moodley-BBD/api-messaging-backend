# Configure the AWS provider
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

# Configure the PostgreSQL provider
provider "postgresql" {
  host            = aws_db_instance.api_messenger_db.address
  port            = 5432
  username        = var.db_username
  password        = var.db_password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}

# Random ID resource for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get all availability zones in the region
data "aws_availability_zones" "available_zones" {}

# Use default subnets instead of creating new ones
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

# Create a security group with a unique name to avoid duplication
resource "aws_security_group" "db_sg" {
  name        = "api-messenger-db-sg-${random_id.suffix.hex}"
  description = "Security group for API Messenger database"
  vpc_id      = data.aws_vpc.default.id
  
  ingress {
    from_port   = 5432  # PostgreSQL port
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Consider restricting this for better security
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create PostgreSQL DB instance
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

# Create the database using the PostgreSQL provider
resource "postgresql_database" "db" {
  name      = var.db_name
  owner     = var.db_username
  
  # Make sure RDS instance is available before attempting to create the database
  depends_on = [aws_db_instance.api_messenger_db]
}

# Output the DB endpoint for easy access
output "db_host" {
  value       = aws_db_instance.api_messenger_db.endpoint
  description = "The endpoint of the PostgreSQL RDS instance"
}