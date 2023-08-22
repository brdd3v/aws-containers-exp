resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.0/20"
  availability_zone = "eu-central-1a"
}

resource "aws_subnet" "public_1b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.16.0/20"
  availability_zone = "eu-central-1b"
}

resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.32.0/20"
  availability_zone = "eu-central-1a"
}

resource "aws_subnet" "private_1b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.64.0/20"
  availability_zone = "eu-central-1b"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_eip" "nat_gw_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = aws_subnet.public_1a.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.private.id
}
