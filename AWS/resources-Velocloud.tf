// ----- Velocloud Section ----- //

/* STEPS
1- Create velocloud interfaces
2- Create SSH key pair
3- Create Velocloud instance
4- create static route to reach the private cloud management subnet via Velocloud CloudVPN
*/


// 1- Create velocloud interfaces

// GE1 definition - Management interface
resource "aws_network_interface" "aws_velo-ge1" { 
    subnet_id = aws_subnet.aws_vcn-public-sn.id 
    source_dest_check = false
    security_groups = [aws_security_group.aws_vcn-sg-wan.id]
}

// GE2 definition - WAN interface
resource "aws_network_interface" "aws_velo-ge2" { 
    subnet_id = aws_subnet.aws_vcn-public-sn.id 
    source_dest_check = false
    security_groups = [aws_security_group.aws_vcn-sg-wan.id]
}

// GE3 definition - LAN interface
resource "aws_network_interface" "aws_velo-ge3" { 
    subnet_id = aws_subnet.aws_vcn-private-sn.id 
    private_ips = [var.aws_private_ip]
    source_dest_check = false
    security_groups = [aws_security_group.aws_vcn-sg-lan.id]
}

// 2- Create SSH key pair
resource "tls_private_key" "aws_velo-key" {
  algorithm = "RSA"
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  public_key = tls_private_key.aws_velo-key.public_key_openssh
  key_name = var.aws_key_name
}

// 3- Create Velocloud instance
resource "aws_instance" "aws_velo-instance" { 
    instance_type = var.aws_instance_type
    key_name = var.aws_key_name
    ami = lookup(var.aws_amis, var.aws_region)
    user_data = file("cloud-init-aws")
    network_interface {
        network_interface_id = aws_network_interface.aws_velo-ge1.id
        device_index  = 0
    }
    network_interface {
        network_interface_id = aws_network_interface.aws_velo-ge2.id 
        device_index = 1
    }
    network_interface {
        network_interface_id = aws_network_interface.aws_velo-ge3.id 
        device_index = 2
        }
    tags = {
        Name = "vce"
    }
}

// Elastic IP creation for WAN
resource "aws_eip" "aws_velo-ge2-eip" {
    network_interface = aws_network_interface.aws_velo-ge2.id
    vpc = true
    depends_on = [aws_instance.aws_velo-instance]
    tags = {
        Name = "velo-ge2-eip"
    }
}

// 4- create static route to reach the private cloud management subnet via Velocloud CloudVPN
resource "aws_route" "aws_branch_route" {
    route_table_id = aws_vpc.aws_vcn-vpc.main_route_table_id
    depends_on = [aws_instance.aws_velo-instance, aws_network_interface.aws_velo-ge3]
    destination_cidr_block = "10.5.99.0/24"
    network_interface_id = aws_network_interface.aws_velo-ge3.id
}