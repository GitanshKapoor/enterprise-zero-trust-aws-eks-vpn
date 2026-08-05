

resource "aws_vpc" "project_vpc" {
    cidr_block = var.vpc_cidr

    enable_dns_support   = true
    enable_dns_hostnames = true

    tags = {
        Name = var.vpc_name,
        environment = "POC"
    }
}

resource "aws_internet_gateway" "project_igw" {
    vpc_id = aws_vpc.project_vpc.id 
    
    tags = {
        name = "${var.vpc_name}-igw"
    }        # As IGW is a VPC level resouce it needs to be assciated with a VPC. We can do this by passing the VPC ID to the IGW resource.
}

resource "aws_subnet" "project_public_subnet" {

    count = local.psub_count
    vpc_id = aws_vpc.project_vpc.id

    cidr_block = var.public_subnet_cidrs[count.index]

    availability_zone = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.vpc_name}-public-subnet-${count.index + 1}",
        "kubernetes.io/role/elb" = "1"
    }

}

resource "aws_subnet" "project_private_subnet" {

    count = local.pisub_count
    vpc_id = aws_vpc.project_vpc.id

    cidr_block = var.private_subnet_cidrs[count.index]

    availability_zone = data.aws_availability_zones.available.names[count.index]

    tags = {
        Name = "${var.vpc_name}-private-subnet-${count.index + 1}",
        "kubernetes.io/role/internal-elb" = "1"
    }
}

resource "aws_eip" "project_nat_eip" {
    domain = "vpc"
}

resource "aws_nat_gateway" "project_nat" {

    subnet_id = aws_subnet.project_public_subnet[0].id
    allocation_id = aws_eip.project_nat_eip.id

    depends_on = [aws_internet_gateway.project_igw, aws_eip.project_nat_eip]

    tags = {
        Name = "${var.vpc_name}-nat-gateway"
    }
}

resource "aws_route_table" "project_public_rt" {
    vpc_id = aws_vpc.project_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.project_igw.id
    }

}

resource "aws_route_table" "project_private_rt" {
    vpc_id = aws_vpc.project_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.project_nat.id
    }
}

resource "aws_route_table_association" "project_public_rta" {
    count = local.psub_count
    subnet_id = aws_subnet.project_public_subnet[count.index].id
    route_table_id = aws_route_table.project_public_rt.id
}

resource "aws_route_table_association" "project_private_rta" {
    count = local.pisub_count
    subnet_id = aws_subnet.project_private_subnet[count.index].id
    route_table_id = aws_route_table.project_private_rt.id
}