data "aws_availability_zones" "available" {
  state = "available"
}
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
 

  tags = {
    Name = "${var.environment}-VPC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.environment}-IGW"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-Public-Subnet-A"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 2)
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-Public-Subnet-B"
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 3)
  availability_zone = data.aws_availability_zones.available.names[0]
  

  tags = {
    Name = "${var.environment}-Private-Subnet-A"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 4)
  availability_zone = data.aws_availability_zones.available.names[1]
  

  tags = {
    Name = "${var.environment}-Private-Subnet-B"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.environment}-Public-RT"
  }
}


resource "aws_route_table_association" "public_assoc_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

 
  tags = {
    Name = "${var.environment}-Private-RT"
  }
}


resource "aws_route_table_association" "private_assoc_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt.id
}
# 1. تخصيص IP ثابت للـ NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# 2. إنشاء الـ NAT Gateway في الـ Public Subnet (استخدمت Subnet A)
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_a.id 

  depends_on = [aws_internet_gateway.gw]
}

# 3. تعديل الـ Private Route Table عشان يبعت الترافيك للـ NAT
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}