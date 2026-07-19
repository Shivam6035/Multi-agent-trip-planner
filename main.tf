# 1. AWS Provider Setup (Unchanged)
provider "aws" {
  region = "us-east-1"
}

# 2. Network: VPC and Subnets
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "main-app-vpc" }
}

# Internet Gateway - The door to the public internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-vpc-igw" }
}

# Route Table - Directs internet-bound traffic to the Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = { Name = "public-route-table" }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "db-subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags              = { Name = "db-subnet-2" }
}

# Associate Subnets with the Route Table so they have internet access paths
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.public_rt.id
}

# 3. Database Subnet Group
resource "aws_db_subnet_group" "postgres_subnet_group" {
  name       = "postgres-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

# 4. Security Group (Firewall Rules)
resource "aws_security_group" "db_sg" {
  name        = "postgres-security-group"
  description = "Allow PostgreSQL inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow Postgres from inside the VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restricts access to resources within this VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 5. The RDS PostgreSQL Instance
resource "aws_db_instance" "postgres_db" {
  identifier          = "my-app-database"
  engine              = "postgres"
  engine_version      = "16.3"         # Use the latest stable version
  instance_class      = "db.t4g.micro" # Great for dev/testing (ARM-based)
  allocated_storage   = 20
  storage_type        = "gp3"
  publicly_accessible = true # Gives the DB a public IP address

  db_name  = "appdb" # The initial database created
  username = "dbadmin"
  password = "SuperSecret123!" # Note: Use AWS Secrets Manager for production

  db_subnet_group_name   = aws_db_subnet_group.postgres_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]


  skip_final_snapshot = true  # Set to 'false' in production so you don't lose data on deletion
  multi_az            = false # Set to 'true' for production high availability
}

# 6. Output the Connection URL
output "database_endpoint" {
  value = aws_db_instance.postgres_db.endpoint
}


# 7 S3 bucket

resource "aws_s3_bucket" "terraform_state" {
  bucket = "shivam-nitr-tripmate-state" # Change this to a globally unique name
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}


terraform {
   backend "s3" {
     bucket         = "shivam-nitr-tripmate-state"
     key            = "global/s3/terraform.tfstate"
     region         = "us-east-1"
     encrypt        = true
   }
}