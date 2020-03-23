// "aws_vpc" defines VPC.
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "example"
  }
}

/*
---------------
Public subnet.
---------------
*/

// "aws_subnet" defines subnet. The below is a public subnet.
// Here, create two public subnets "public_0" and "public_1" in different AZ.
resource "aws_subnet" "public_0" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"
}

// "aws_internet_gateway" makes VPC have an internet access.
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

// "aws_route_table" manages routing information to send data to the network.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
}

// "aws_route" is a route record. Specify a default route(0.0.0.0/0) to send data to the Internet via internet gateway.
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}

// "aws_route_table_association" attaches route table to subnet.
// Here, attach to two public subnets "public_0" and "public_1".
resource "aws_route_table_association" "public_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

/*
---------------
Private subnet.
---------------
*/

// The below is a private subnet.
// Here, create two private subnets "private_0" and "private_1" in different AZ.
resource "aws_subnet" "private_0" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.65.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.66.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false
}

resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

// "aws_eip" defines elastic IP.
resource "aws_eip" "nat_gateway_0" {
  // The vpc is an option if the EIP is in a VPC or not.
  // The depends_on to set an explicit dependency on the IGW. This ensure that EIP and NAT gateways are created after creating an Internet gateway
  vpc        = true
  depends_on = [aws_internet_gateway.example]
}

resource "aws_eip" "nat_gateway_1" {
  vpc        = true
  depends_on = [aws_internet_gateway.example]
}

// "aws_nat_gateway" defines NAT gateway.
// NAT gateway gives private subnet to the internet.
resource "aws_nat_gateway" "nat_gateway_0" {
  // Set public subnet not private subnet to subnet_id here.
  // The depends_on to set an explicit dependency on the IGW. This ensure that EIP and NAT gateways are created after creating an Internet gateway
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.public_0.id
  depends_on    = [aws_internet_gateway.example]
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.example]
}

// "aws_route" defines route to communicate private subnet to the internet.
resource "aws_route" "private_0" {
  route_table_id         = aws_route_table.private_0.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}

/*
---------------
Security Group
---------------
*/

module "example_sg" {
  source      = "../security_group"
  name        = "module-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}
