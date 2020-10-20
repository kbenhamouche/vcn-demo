//outputs

output "gcp_vm-web_ip" {
    depends_on = [google_compute_instance.gcp_web-vm]
    value = "${google_compute_instance.gcp_web-vm.network_interface.0.network_ip}"
}

output "gcp_vce_private-key" {
    value = tls_private_key.gcp_velo-key.private_key_pem
}

/*
output "gcp_floating_ip" {
   depends_on = [avi_vsvip.gcp_vsvip]
   value = element(avi_vsvip.gcp_vsvip.vip.0.floating_ip.*.addr,0)
}
*/