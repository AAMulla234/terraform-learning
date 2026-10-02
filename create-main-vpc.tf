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
  public_cidr  = [local.cidrsubnets[0]]                       # only 1 public
  private_cidr = [local.cidrsubnets[1], local.cidrsubnets[2]] # 2 private subnets
  db_cidr      = [local.cidrsubnets[3]]

  additional_cidr_dc = lookup(var.dc_subnet_cidrs[var.env], var.slice)

}

resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr
  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.alias}-${var.env}"
  })
}

resource "aws_subnet" "main_dc" {
  count = var.use_direct_connect ? length(data.aws_availability_zones.available.names) : 0

  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = local.additional_cidr_dc[count.index]

  tags = {
    "Name" = "contact-dc-${count.index + 1}"
  }

  availability_zone = data.aws_availability_zones.available.names[count.index]
}


