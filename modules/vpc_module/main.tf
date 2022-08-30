resource "aws_vpc" "pro_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "pro_vpc"
  }
}

resource "aws_internet_gateway" "pro_igw" {
  vpc_id = aws_vpc.pro_vpc.id

  tags = {
    Name = "pro_igw"
  }
}

resource "aws_subnet" "pub_subnet" {
  vpc_id            = aws_vpc.pro_vpc.id
  cidr_block        = var.subnets[0]
  availability_zone = var.availability_zone[0]

  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "priv_subnet" {
  vpc_id            = aws_vpc.pro_vpc.id
  cidr_block        = var.subnets[1]
  availability_zone = var.availability_zone[1]

  tags = {
    Name = "private_subnet"
  }
}

resource "aws_route_table" "pro_rt_igw" {
  vpc_id = aws_vpc.pro_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pro_igw.id
  }

  tags = {
    Name = "pro_igw_rt"
  }
}

resource "aws_route_table" "pro_rt_nat" {
  vpc_id = aws_vpc.pro_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.pro_nat.id
  }

  tags = {
    Name = "pro_nat_rt"
  }
}

resource "aws_route_table_association" "pro_rtass_igw" {
  subnet_id      = aws_subnet.pub_subnet.id
  route_table_id = aws_route_table.pro_rt_igw.id
}

resource "aws_route_table_association" "pro_rtass_nat" {
  subnet_id      = aws_subnet.priv_subnet.id
  route_table_id = aws_route_table.pro_rt_nat.id
}

resource "aws_eip" "pro_eip" {
  vpc = true 
}

resource "aws_nat_gateway" "pro_nat" {
  allocation_id = aws_eip.pro_eip.id
  subnet_id = aws_subnet.pub_subnet.id

  depends_on = [
    aws_internet_gateway.pro_igw
  ]
}