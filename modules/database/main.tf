# Security Group لطبقة قواعد البيانات (تسمح بالاتصال فقط من Application EC2)
resource "aws_security_group" "db_sg" {
  name        = "${var.environment}-database-sg"
  description = "Allow traffic from Application EC2"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from App EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.app_sg_id]
  }

  ingress {
    description     = "Redis/ElastiCache from App EC2"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.app_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Subnet Group الخاصة بقواعد البيانات
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.environment}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${var.environment}-DB-Subnet-Group" }
}

# 1- Create RDS (MySQL)
resource "aws_db_instance" "app_db" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  identifier             = "${var.environment}-app-database"
  username               = "admin"
  password               = "password123" 
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true # لتسهيل الحذف أثناء التطوير
}

# Subnet Group الخاصة بـ ElastiCache
resource "aws_elasticache_subnet_group" "cache_subnet_group" {
  name       = "${var.environment}-cache-subnet-group"
  subnet_ids = var.private_subnet_ids
}

# 2- Create ElastiCache (Redis)
resource "aws_elasticache_cluster" "app_cache" {
  cluster_id           = "${var.environment}-app-cache"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.cache_subnet_group.name
  security_group_ids   = [aws_security_group.db_sg.id]
}