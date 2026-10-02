locals {

  # list of possible subnets required in vpc (1 public, 2 private * 2 az's = 5 max)
  cidrsubnets = cidrsubnets(var.vpc_cidr, 8, 8, 8, 8, 8)

  # count availability zones

  az_count = length(data.aws_availability_zones.available.names)

# Generate only what's needed: 5 subnets
  #   0 = public
  #   1–2 = private
  #   3 = db
  #   4 = spare (if needed later)

  # Define required subnet groups
  public_cidr  = [local.cidrsubnets[0]]              # only 1 public
  private_cidr = [local.cidrsubnets[1], local.cidrsubnets[2]]  # 2 private subnets
  db_cidr      = [local.cidrsubnets[3]]       

}

resource "aws_vpc" "demo_vpc" {
  cidr_block = var.vpc_cidr
  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.alias}-${var.env}"
  })
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "10.0.0.0/24"
  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.alias}-${var.env}"
    tier = "Public"
  })

}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.alias}-${var.env}"
    tier = "Private"
  })
}

# ****************************************************************************
# *                        attach private subnets to TGWs                         *
# ****************************************************************************

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.demo_vpc.id
  tags = merge(local.common_tags, {
    Name = "private-rt-${var.project}-${var.alias}-${var.env}"
  })
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_ec2_transit_gateway" "tgw" {
  description = "TGW for ${var.project}-${var.env}"
  tags = merge(local.common_tags, {
    Name = "tgw-${var.project}-${var.env}"
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.demo_vpc.id
  subnet_ids         = [aws_subnet.private_subnet.id]

  tags = merge(local.common_tags, {
    Name = "tgw-attach-${var.project}-${var.env}"
  })
}

resource "aws_route" "private_to_tgw" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0" # or your specific destination
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# ****************************************************************************
# *                        attach public subnets to TGWs                         *
# ****************************************************************************


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.demo_vpc.id
  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.alias}-${var.env}"
  })
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(local.common_tags, {
    Name = "public-rt-${var.project}-${var.alias}-${var.env}"
  })
}

resource "aws_route_table_association" "public_subnet" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route.id
}
