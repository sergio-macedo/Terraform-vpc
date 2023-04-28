resource "aws_vpc" "sergio-vpc" {
  cidr_block           = "10.110.99.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name" = "sergio-vpc-1"
  }
}

resource "aws_subnet" "public-subnets" {
  count                   = length(var.subnet_cidr_public)
  vpc_id                  = aws_vpc.sergio-vpc.id
  cidr_block              = var.subnet_cidr_public[count.index]
  availability_zone       = var.availability_zone[count.index]
  map_public_ip_on_launch = "true"
  tags = {
    "Name" = "Public subnet ${count.index + 1}"
  }
}


resource "aws_subnet" "private_subnets" {
  count                   = length(var.subnet_cidr_private)
  vpc_id                  = aws_vpc.sergio-vpc.id
  cidr_block              = var.subnet_cidr_private[count.index]
  availability_zone       = var.availability_zone[count.index]
  map_public_ip_on_launch = "false"
  tags = {
    "Name" = "Private subnet ${count.index + 1}"
  }
}
# Create Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.sergio-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sergio-igw.id
  }
  tags = {
    Name = "public subnet route table"
  }
}
# Create route table association of public subnets
resource "aws_route_table_association" "internet_for_pub_sub" {
  count                   = length(var.subnet_cidr_public)
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public-subnets[count.index].id
}
resource "aws_internet_gateway" "sergio-igw" {
  vpc_id = aws_vpc.sergio-vpc.id
  tags = {
    "Name" = "sergio-internet-gateway"
  }
}

resource "aws_eip" "nat-eips" {
  count = length(var.subnet_cidr_public)
  vpc   = true
}

resource "aws_nat_gateway" "sergio-nat-gateway" {
  count         = length(var.subnet_cidr_public)
  allocation_id = aws_eip.nat-eips[count.index].id
  subnet_id     = aws_subnet.public-subnets[count.index].id
}



resource "aws_route_table" "private_route_tables" {
  count  = length(var.subnet_cidr_private)
  vpc_id = aws_vpc.sergio-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sergio-nat-gateway[count.index].id
  }
  tags = {
    "Name" = "sergio-route-table ${count.index + 1}"
  }
}

resource "aws_route_table_association" "asso-private" {
  count          = length(var.subnet_cidr_private)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_tables[count.index].id
}











#resource "aws_route_table" "private_route" {
#  vpc_id = aws_vpc.sergio-vpc.id
#  route {
#    gateway_id = aws_internet_gateway.sergio-igw.id
#    cidr_block = "0.0.0.0/0"
#  }
#
#  tags = {
#    Name = "my-private-route-table"
#  }
#}
#
#resource "aws_route_table_association" "private-rta" {
#  subnet_id      = aws_subnet.public-subnet.id
#  route_table_id = aws_route_table.private_route.id
#}