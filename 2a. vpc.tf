resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"

  # Required for EKS, Enable/disable DNS support in the VPC
  enable_dns_support = true

  # Required for EKS, Enable/disable DNS hostnames in the VPC
  enable_dns_hostnames = true

  # Requests an Amazon-provided IPv6 CIDR block with a /56 bit
  assign_generated_ipv6_cidr_block = false

  #A map of tags to assign to the resource.

  tags = {
    Name = "Main"
  }

}

# internet gateway

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# PUBLIC SUBNETs

resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "ap-south-1a"

  tags = {
    Name                        = "public subnet1"
    "kubernetes.io/cluster/eks" = "shared"
    "kubernetes.io/role/elb"    = 1
  }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  cidr_block              = "192.168.2.0/24"
  availability_zone       = "ap-south-1b"

  tags = {
    Name                        = "public subnet2"
    "kubernetes.io/cluster/eks" = "shared"
    "kubernetes.io/role/elb"    = 1
  }
}

#Private subnet

resource "aws_subnet" "private1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.3.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false

  tags = {
    Name                        = "Private subnet1"
    "kubernetes.io/cluster/eks" = "shared"
    "kubernetes.io/role/elb"    = 1
  }
}

resource "aws_subnet" "private2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.4.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = false

  tags = {
    Name                        = "Private subnet2"
    "kubernetes.io/cluster/eks" = "shared"
    "kubernetes.io/role/elb"    = 1
  }

}

# Elastic-ip-addresses

resource "aws_eip" "nat1" {
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = "NAT 1"
  }

}

resource "aws_eip" "nat2" {
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat2" {
  allocation_id = aws_eip.nat2.id
  subnet_id     = aws_subnet.public2.id

  tags = {
    Name = "NAT 2"
  }

}

#root table and assosiation with subnet

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public"
  }
}

resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat1.id
  }

  tags = {
    Name = "private1"
  }
}

resource "aws_route_table" "private2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat2.id
  }

  tags = {
    Name = "private2"
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private1.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private2.id
}

