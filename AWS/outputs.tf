//outputs

output "aws_vm-web_ip" {
    depends_on = [aws_instance.aws_web-vm]
    value = "${aws_instance.aws_web-vm.private_ip}"
}

output "aws_vm_private-key" {
    value = tls_private_key.aws_vm-key.private_key_pem
}

output "aws_vce_private-key" {
    value = tls_private_key.aws_velo-key.private_key_pem
}

/*
output "aws_floating_ip" {
   depends_on = [avi_vsvip.aws_vsvip]
   value = element(avi_vsvip.aws_vsvip.vip.0.floating_ip.*.addr,0)
}
*/