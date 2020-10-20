// ----- Azure and Velocloud Section ----- //

/* STEPS
1- create Azure Resource Group
2- create VNET
3- create VNET subnets
4- Create Allocation public IP
5- Create routing tables
6- Create NSG
7- create a Web server instance
*/

// 1- Create Resource Group
resource "azurerm_resource_group" "vcn-demo-rg" { 
    name = "vcn-demo-rg"
    location = var.azure_region
}
// 2- create VNET
resource "azurerm_virtual_network" "vcn-vnet" {
    name = "vcn-demo-vnet"
    resource_group_name = azurerm_resource_group.vcn-demo-rg.name
    location = azurerm_resource_group.vcn-demo-rg.location
    address_space = [var.azure_vnet_cidr_block]
}

// 3- define public subnet
resource "azurerm_subnet" "vcn-public-sn" {
    name = "vcn-public-sn"
    resource_group_name = azurerm_resource_group.vcn-demo-rg.name
    virtual_network_name = azurerm_virtual_network.vcn-vnet.name 
    address_prefixes = [var.azure_public_sn_cidr_block]
}

// 3- define private subnet
resource "azurerm_subnet" "vcn-private-sn" {
    name = "vcn-private-sn"
    resource_group_name = azurerm_resource_group.vcn-demo-rg.name
    virtual_network_name = azurerm_virtual_network.vcn-vnet.name 
    address_prefixes = [var.azure_private_sn_cidr_block]
}

// 4- Allocation public IP
resource "azurerm_public_ip" "velo-pubip" {
    name = "velo-pubip"
    location = var.azure_region
    resource_group_name = azurerm_resource_group.vcn-demo-rg.name
    allocation_method = "Static"
    tags = {
        environment = "velo-pubip"
    }
}

// 5- Create Routing table for public access
resource "azurerm_route_table" "vcn-public-rt" {
    name = "vcn-public-rt"
    location = azurerm_resource_group.vcn-demo-rg.location 
    resource_group_name = azurerm_resource_group.vcn-demo-rg.name
}

// 5- Associate public route table to subnet
resource "azurerm_subnet_route_table_association" "public2rt" {
  subnet_id = azurerm_subnet.vcn-public-sn.id
  route_table_id = azurerm_route_table.vcn-public-rt.id
}

// 5- Configure default route
resource "azurerm_route" "default-route" {
    name = "default-route"
    resource_group_name = azurerm_resource_group.vcn-demo-rg.name 
    route_table_name = azurerm_route_table.vcn-public-rt.name
    address_prefix = "0.0.0.0/0"
    next_hop_type = "Internet"
}

// 5- Create Routing table for private access
resource "azurerm_route_table" "vcn-private-rt" {
    name = "vcn-private-rt"
    location = azurerm_resource_group.vcn-demo-rg.location 
    resource_group_name = azurerm_resource_group.vcn-demo-rg.name
}

// 5- Associate private route table to subnet
resource "azurerm_subnet_route_table_association" "private2rt" {
  subnet_id = azurerm_subnet.vcn-private-sn.id
  route_table_id = azurerm_route_table.vcn-private-rt.id
}

// 6- define security group for LAN interface
resource "azurerm_network_security_group" "vcn-sg-lan" {
  name = "vcn-sg-lan"
  location = azurerm_resource_group.vcn-demo-rg.location
  resource_group_name = azurerm_resource_group.vcn-demo-rg.name
  security_rule {
    name = "AllowALL"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "*"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
  tags = {
    environment = "velo-sg-lan"
  }
}

// 6- define security group for WAN interface
resource "azurerm_network_security_group" "vcn-sg-wan" {
  name = "vcn-sg-wan"
  location = azurerm_resource_group.vcn-demo-rg.location
  resource_group_name = azurerm_resource_group.vcn-demo-rg.name
  security_rule {
    name = "AllowSSH"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name = "AllowVCMP"
    priority = 101
    direction = "Inbound"
    access = "Allow"
    protocol = "Udp"
    source_port_range = "*"
    destination_port_range = "2426"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
  tags = {
    environment = "velo-sg-wan"
  }
}



// 7- Create a web server
resource "tls_private_key" "azure_vm-key" {
  algorithm = "RSA"
}

// 7- VM LAN interface
resource "azurerm_network_interface" "web-vm-if" {
    name = "web-vm-if"
    location = azurerm_resource_group.vcn-demo-rg.location 
    resource_group_name = azurerm_resource_group.vcn-demo-rg.name 
    //enable_ip_forwarding = true
    ip_configuration {
        name = "web-vm-ip"
        subnet_id = azurerm_subnet.vcn-private-sn.id
        private_ip_address_allocation = "Dynamic"
    }
    tags = {
        environment = "web-vm-if"
    } 
}

resource "azurerm_network_interface_security_group_association" "sg-lan-vm" {
  network_interface_id = azurerm_network_interface.web-vm-if.id
  network_security_group_id = azurerm_network_security_group.vcn-sg-lan.id
}

resource "azurerm_virtual_machine" "azure_web-vm" {
    name = "web-vm"
    location = azurerm_resource_group.vcn-demo-rg.location 
    resource_group_name = azurerm_resource_group.vcn-demo-rg.name
    network_interface_ids = [azurerm_network_interface.web-vm-if.id]
    vm_size = "Standard_B1s"
    delete_os_disk_on_termination = true 
    delete_data_disks_on_termination = true 
    primary_network_interface_id = azurerm_network_interface.web-vm-if.id
    
    storage_image_reference {
        publisher = "bitnami"
        offer = "nginxstack"
        sku = "1-9"
        version = "1.18.2008200520"
    }

    plan {
        name = "1-9"
        publisher = "bitnami"
        product = "nginxstack"
    }

    storage_os_disk {
        name = "vm-disk"
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name  = "nginx"
        admin_username = "bitnami"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path = "/home/bitnami/.ssh/authorized_keys"
            key_data = tls_private_key.azure_vm-key.public_key_openssh
        }
    }
    
    tags = {
        environment = "production"
    }
}