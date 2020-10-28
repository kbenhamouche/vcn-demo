// ----- AWS Section ----- //

/* STEPS
1- create AWS VPC
2- create AWS VPC subnets
3- create AWS SG rules
4- create a Web server instance
*/

// 1- Create VPC
resource "aws_vpc" "aws_vcn-vpc" {
    cidr_block = var.aws_vpc_cidr_block
    tags = {
        Name = "demo-vpc"
    }
}

// 2- AWS VPC subnets

// define public subnet
resource "aws_subnet" "aws_vcn-public-sn" {
    vpc_id = aws_vpc.aws_vcn-vpc.id 
    cidr_block = var.aws_public_sn_cidr_block 
    availability_zone = var.aws_availability_zone 
    map_public_ip_on_launch = false
    tags = {
        Name = "demo-public-sn"
        }
}

// define private subnet
resource "aws_subnet" "aws_vcn-private-sn" {
    vpc_id = aws_vpc.aws_vcn-vpc.id 
    cidr_block = var.aws_private_sn_cidr_block
    availability_zone = var.aws_availability_zone
    map_public_ip_on_launch = false
    tags = {
        Name = "demo-private-sn"
    }
}

// tags the AWS IGW
resource "aws_internet_gateway" "aws_vcn-igw" { 
    vpc_id = aws_vpc.aws_vcn-vpc.id
    tags = {
        Name = "demo-igw"
    }
}

// configure default route
resource "aws_route" "aws_vcn-public-rt" {
    route_table_id = aws_vpc.aws_vcn-vpc.main_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_vcn-igw.id
}

// 3- create AWS SG rules

// define security group for LAN interface
resource "aws_security_group" "aws_vcn-sg-lan" {
    vpc_id = aws_vpc.aws_vcn-vpc.id
    tags = {
        Name = "demo-sg-lan"
    }
    // ALL
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    // ALL
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

// define security group for WAN interface
resource "aws_security_group" "aws_vcn-sg-wan" {
    vpc_id = aws_vpc.aws_vcn-vpc.id
    tags = {
        Name = "demo-sg-wan"
    }
    // SSH
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    // VCMP
    ingress {
        from_port = 2426
        to_port = 2426
        protocol = "udp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    // ALL
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


// 4- Create a Web instance
resource "random_id" "aws_instance_id" {
  byte_length = 8
}

// key pair creation
resource "tls_private_key" "aws_vm-key" {
  algorithm = "RSA"
}

module "key_pair_vm" {
  source = "terraform-aws-modules/key-pair/aws"
  public_key = tls_private_key.aws_vm-key.public_key_openssh
  key_name = "nginx"
}

// VM definition - private interface
resource "aws_network_interface" "aws_vm-if" { 
    subnet_id = aws_subnet.aws_vcn-private-sn.id 
    source_dest_check = false
    security_groups = [aws_security_group.aws_vcn-sg-lan.id]
}

// VM creation
resource "aws_instance" "aws_web-vm" { 
    //name = "vm-web-${random_id.aws_instance_id.hex}"
    instance_type = "t2.micro"
    key_name = "nginx"
    ami = lookup(var.aws_amis_bitnami, var.aws_region)
    network_interface {
        network_interface_id = aws_network_interface.aws_vm-if.id
        device_index  = 0
    }
    user_data = file("cloud-init-aws-nginx")
    tags = {
        Name = "nginx"
    }
}