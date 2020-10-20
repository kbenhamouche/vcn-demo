//outputs

output "azure_vm-web_ip" {
    depends_on = [azurerm_virtual_machine.azure_web-vm]
    value = "${azurerm_network_interface.web-vm-if.private_ip_address}"
}

output "azure_vm_private-key" {
    value = tls_private_key.azure_vm-key.private_key_pem
}

output "azure_vce_private-key" {
    value = tls_private_key.azure_velo-key.private_key_pem
}

/*
output "azure_floating_ip" {
   depends_on = [avi_vsvip.azure_vsvip]
   value = element(avi_vsvip.azure_vsvip.vip.0.floating_ip.*.addr,0)
}
*/