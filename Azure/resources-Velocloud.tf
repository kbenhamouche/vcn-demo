// ----- Velocloud Section ----- //

/* STEPS
1- Create velocloud interfaces
2- Associate existing NSG to velocloud interfaces
3- Create SSH key pair
4- Create Velocloud instance
5- create static route to reach the private cloud management subnet via Velocloud CloudVPN
*/

// 1- Create velocloud interfaces

// GE1 definition - Management interface
resource "azurerm_network_interface" "velo-ge1" {
    name = "velo-ge1"
    location = azurerm_resource_group.vcn-demo-rg.location 
    resource_group_name = azurerm_resource_group.vcn-demo-rg.name 
    enable_ip_forwarding = true
    ip_configuration {
        name = "velo-ge1-ip"
        subnet_id = azurerm_subnet.vcn-public-sn.id
        private_ip_address_allocation = "Dynamic"
    }
    tags = {
        environment = "velo-ge1"
    } 
}

// GE2 definition - WAN interface
resource "azurerm_network_interface" "velo-ge2" {
    name = "velo-ge2"
    location = azurerm_resource_group.vcn-demo-rg.location 
    resource_group_name = azurerm_resource_group.vcn-demo-rg.name 
    enable_ip_forwarding = true
    ip_configuration {
        name = "velo-ge2-ip"
        subnet_id = azurerm_subnet.vcn-public-sn.id
        private_ip_address_allocation = "Static"
        private_ip_address = var.azure_public_ip
        public_ip_address_id = azurerm_public_ip.velo-pubip.id
    }
    tags = {
        environment = "velo-ge2"
    } 
}

// GE3 definition - LAN interface
resource "azurerm_network_interface" "velo-ge3" {
    name = "velo-ge3"
    location = azurerm_resource_group.vcn-demo-rg.location 
    resource_group_name = azurerm_resource_group.vcn-demo-rg.name 
    enable_ip_forwarding = true
    ip_configuration {
        name = "velo-ge3-ip"
        subnet_id = azurerm_subnet.vcn-private-sn.id
        private_ip_address_allocation = "Static"
        private_ip_address = var.azure_private_ip 
    }
    tags = {
        environment = "velo-ge3"
    } 
}

// 2- Associate NSG to interfaces
resource "azurerm_network_interface_security_group_association" "sg-lan-ge1" {
  network_interface_id = azurerm_network_interface.velo-ge1.id
  network_security_group_id = azurerm_network_security_group.vcn-sg-lan.id
}

resource "azurerm_network_interface_security_group_association" "sg-lan-ge3" {
  network_interface_id = azurerm_network_interface.velo-ge3.id
  network_security_group_id = azurerm_network_security_group.vcn-sg-lan.id
}

resource "azurerm_network_interface_security_group_association" "sg-wan-ge2" {
  network_interface_id = azurerm_network_interface.velo-ge2.id
  network_security_group_id = azurerm_network_security_group.vcn-sg-wan.id
}

// 3- key pair creation
resource "tls_private_key" "azure_velo-key" {
  algorithm = "RSA"
}

// 4- VCE creation
resource "azurerm_virtual_machine" "velo-vedge" {
    name = "velo-vedge"
    location = azurerm_resource_group.vcn-demo-rg.location 
    resource_group_name = azurerm_resource_group.vcn-demo-rg.name
    network_interface_ids = [azurerm_network_interface.velo-ge1.id,azurerm_network_interface.velo-ge2.id,azurerm_network_interface.velo-ge3.id]
    vm_size = var.instance_type 
    delete_os_disk_on_termination = true 
    delete_data_disks_on_termination = true 
    primary_network_interface_id = azurerm_network_interface.velo-ge2.id
    
    storage_image_reference {
        publisher = "velocloud"
        offer = "velocloud-virtual-edge-3x"
        sku = "velocloud-virtual-edge-3x"
        version = "3.3.2"
    }

    plan {
        name = "velocloud-virtual-edge-3x"
        publisher = "velocloud"
        product = "velocloud-virtual-edge-3x"
    }

    storage_os_disk {
        name = "velo-disk"
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Standard_LRS"
    }
    
    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path = "/home/vce/.ssh/authorized_keys"
            key_data = tls_private_key.azure_velo-key.public_key_openssh
        }
    }
    
    os_profile {
        computer_name  = "velo-vce"
        admin_username = var.vce_username
        custom_data = file("cloud-init-azure")
    }
    
    tags = {
        environment = "production"
    }
}

// 5- Static route for branch (example)
resource "azurerm_route" "branch_route" {
    name = "branch-route"
    resource_group_name = azurerm_resource_group.vcn-demo-rg.name 
    route_table_name = azurerm_route_table.vcn-private-rt.name
    address_prefix = "10.5.99.0/24"
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = var.azure_private_ip
}