// ----- Velocloud Section ----- //

/* STEPS
1- Create SSH key pair
2- Create Velocloud instance
3- create static route to reach the private cloud management subnet via Velocloud CloudVPN
*/


// 1- Create SSH key pair

// Key pair creation for velocloud edge
resource "tls_private_key" "gcp_velo-key" {
  algorithm = "RSA"
}

// 2- Create the instance
resource "google_compute_instance" "gcp_vce_instance" { 
    name = "vce" 
    machine_type = var.gcp_instance_type
    can_ip_forward = true
    boot_disk {
        initialize_params {
            image = "https://www.googleapis.com/compute/v1/projects/vmware-sdwan-public/global/images/vce-342-102-r342-20200610-ga-3f5ad3b9e2"
            } 
    }
    metadata = {
        user-data = file("cloud-init-gcp")
        //user-data = "#cloud-config\n velocloud:\n vce:\n vco: vco12-usvi1.velocloud.net\n activation_code: 2CMR-Y8AL-TJ73-TYRH\n vco_ignore_cert_errors: true\n"
        ssh-keys = tls_private_key.gcp_velo-key.public_key_openssh
    }
    // GE1 interface
    network_interface {
        subnetwork = google_compute_subnetwork.gcp_vcn_mngt_sn.id
    }
    // GE2 interface
    network_interface {
        subnetwork = google_compute_subnetwork.gcp_vcn_public_sn.id
        access_config {
            //Ephemeral IP
        } 
    }
    // GE3 interface
    network_interface { 
        subnetwork = google_compute_subnetwork.gcp_vcn_private_sn.id
        network_ip = var.gcp_private_ip
    }
}

// 3- create static route to reach the private cloud management subnet via Velocloud CloudVPN
resource "google_compute_route" "branch_route" {
  name        = "branch-route"
  dest_range  = "10.5.99.0/24"
  network     = google_compute_network.gcp_vcn_demo_private_vpc.id
  depends_on    = [google_compute_subnetwork.gcp_vcn_private_sn]
  next_hop_ip = var.gcp_private_ip
  priority    = 100
}