provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "region2"
  region = "eu-central-1"
}

variable "db_instance_name" {
  description = "Name of the RDS instance"
  type        = string
  default     = "my-rds-instance"
}

variable "source_db_instance_identifier" {
  description = "Identifier of the source RDS instance"
  type        = string
  default     = "your-source-instance-identifier"
}

module "rds" {
  source = "terraform-aws-modules/rds/aws"

  db_instance_name           = var.db_instance_name
  allocated_storage          = 20
  instance_class             = "db.t2.micro"
  engine                     = "postgres"
  engine_version             = "13.4" # Choose version of your choice
  name                       = "mydb"
  username                   = "db_user"
  password                   = "db_password"
  skip_final_snapshot        = true
  final_snapshot_identifier  = "final-snapshot"
  publicly_accessible        = false
  vpc_security_group_ids     = [aws_security_group.db_security_group.id]
  db_subnet_group_name       = aws_db_subnet_group.db_subnet_group.name
  parameter_group_name       = "default.postgres13"
  multi_az                   = true
  apply_immediately          = true
  maintenance_window         = "Mon:00:00-Mon:04:00"
  backup_retention_period    = 7
  preferred_maintenance_window = "sun:00:00-sun:04:00"

  # Customize other module parameters as needed
}
resource "aws_security_group" "db_security_group" {
  name_prefix = "db-"
  description = "Security group for RDS"
  
  # Define your ingress rules to allow access to the RDS instances
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Adjust the CIDR block as needed
  }

  # Define egress rules if necessary
}
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = ["subnet-xxxxxx", "subnet-yyyyyy"] # Specify your subnet IDs
}
data "aws_region" "cross_region" {
  name = "us-west-2" # Change to your desired target region
}

module "kms" {
  source      = "terraform-aws-modules/kms/aws"
  version     = "~> 1.0"
  description = "KMS key for cross region replica DB"

  # Aliases
  aliases                 = "pg_read_replica_kms"
  aliases_use_name_prefix = true

  key_owners = [data.aws_caller_identity.current.id]


  providers = {
    aws = aws.region2
  }
}
module "cross_region_read_replica" {
  source = "terraform-aws-modules/rds/aws"
  
  providers = {
    aws = aws.region2
  }

  db_instance_name          = "cross-region-replica"
  allocated_storage         = 20
  instance_class            = "db.t2.micro"
  engine                    = "postgres"
  engine_version            = "13.4" # Choose version of your choice that should match the main db instance
  name                      = "cross_region_replica_db"
  username                  = "db_user"
  password                  = "db_password"
  skip_final_snapshot       = true
  final_snapshot_identifier = "final-snapshot"
  publicly_accessible       = false
  kms_key_id                = module.kms.key_arn
  vpc_security_group_ids    = [aws_security_group.db_security_group_read_replica.id]

  # Specify the ARN of the source RDS instance in the source_db_instance_identifier
  source_db_instance_identifier = module.rds.db_instance_arn
  multi_az                    = false # Cross-region replicas do not support Multi-AZ
  apply_immediately           = true
  maintenance_window          = "Mon:00:00-Mon:04:00"
  backup_retention_period     = 7
  preferred_maintenance_window = "sun:00:00-sun:04:00"

  # Customize other module parameters as needed
}

resource "aws_security_group" "db_security_group_read_replica" {
  name_prefix = "db-"
  description = "Security group for RDS"
  
  providers = {
    aws = aws.region2
  }
  
  # Define your ingress rules to allow access to the RDS instances
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Adjust the CIDR block as needed
  }

  # Define egress rules if necessary
}
