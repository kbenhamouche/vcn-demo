

//AWS
output "aws_vm-web_ip" {
    value = "${module.AWS.aws_vm-web_ip}"
}

output "aws_vm_private-key" {
    value = "${module.AWS.aws_vm_private-key}"
}

output "aws_vce_private-key" {
    value = "${module.AWS.aws_vce_private-key}"
}


//Azure
output "azure_vm-web_ip" {
    value = "${module.Azure.azure_vm-web_ip}"
}

output "azure_vm_private-key" {
    value = "${module.Azure.azure_vm_private-key}"
}

output "azure_vce_private-key" {
    value = "${module.Azure.azure_vce_private-key}"
}


// GCP
output "gcp_vm-web_ip" {
    value = "${module.GCP.gcp_vm-web_ip}"
}

output "gcp_vce_private-key" {
    value = "${module.GCP.gcp_vce_private-key}"
}
