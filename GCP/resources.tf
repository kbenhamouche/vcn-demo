// ----- GCP and Velocloud Section ----- //

/* STEPS
1- create GCP VPC
2- create GCP VPC subnets
3- create GCP FW rules
4- create a Web server instance
*/

// 1- Create VPC
resource "google_compute_network" "gcp_vcn_demo_public_vpc" {
    name = "vcn-demo-public-vpc"
    auto_create_subnetworks = "false"
    routing_mode = "REGIONAL"
}

resource "google_compute_network" "gcp_vcn_demo_private_vpc" {
    name = "vcn-demo-private-vpc"
    auto_create_subnetworks = "false"
    routing_mode = "REGIONAL"
}

resource "google_compute_network" "gcp_vcn_demo_mngt_vpc" {
    name = "vcn-demo-mngt-vpc"
    auto_create_subnetworks = "false"
    routing_mode = "REGIONAL"
}

// 2- Create Subnets
resource "google_compute_subnetwork" "gcp_vcn_public_sn" {
    name          = "vcn-public-sn"
    ip_cidr_range = var.gcp_public_sn_cidr_block
    network       = google_compute_network.gcp_vcn_demo_public_vpc.id
    depends_on    = [google_compute_network.gcp_vcn_demo_public_vpc]
    region = var.gcp_region
}

resource "google_compute_subnetwork" "gcp_vcn_private_sn" {
    name          = "vcn-private-sn"
    ip_cidr_range = var.gcp_private_sn_cidr_block
    network       = google_compute_network.gcp_vcn_demo_private_vpc.id
    depends_on    = [google_compute_network.gcp_vcn_demo_private_vpc]
    region = var.gcp_region 
}

resource "google_compute_subnetwork" "gcp_vcn_mngt_sn" {
    name          = "vcn-mngt-sn"
    ip_cidr_range = var.gcp_mngt_sn_cidr_block
    network       = google_compute_network.gcp_vcn_demo_mngt_vpc.id
    depends_on    = [google_compute_network.gcp_vcn_demo_mngt_vpc]
    region = var.gcp_region 
}

// 3- FW rules
resource "google_compute_firewall" "gcp_public_fw_rules" {
    name = "public-fw-rules"
    network = google_compute_network.gcp_vcn_demo_public_vpc.id
    allow { //SSH
        protocol = "tcp"
        ports = ["22"]
    }
    allow { //VCMP
        protocol = "udp"
        ports = ["2426"]
    }
    allow { //ICMP
        protocol = "icmp"
    }
    source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "gcp_private_fw_rules" {
    name = "private-fw-rules"
    network = google_compute_network.gcp_vcn_demo_private_vpc.id
    allow { //ALL
        protocol = "all"
    }
    source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "gcp_mngt_fw_rules" {
    name = "mngt-fw-rules"
    network = google_compute_network.gcp_vcn_demo_mngt_vpc.id
    allow { //SSH
        protocol = "tcp"
        ports = ["22"]
    }
    allow { //ICMP
        protocol = "icmp"
    }
    source_ranges = ["0.0.0.0/0"]
}

// 4- Create a Web instance
resource "random_id" "gcp_instance_id" {
  byte_length = 8
}

resource "google_compute_instance" "gcp_web-vm" {
    name = "vm-web-${random_id.gcp_instance_id.hex}"
    machine_type = "f1-micro"
    zone  = var.gcp_zone
    boot_disk {
        initialize_params {
            image = "https://www.googleapis.com/compute/v1/projects/bitnami-launchpad/global/images/bitnami-nginx-1-18-0-1-linux-debian-9-x86-64"
        }
    }
    metadata_startup_script = "sed -i 's/Congratulations/& and Welcome on GCP PUBLIC Cloud/' /opt/bitnami/nginx/html/index.html"
    network_interface {
        subnetwork = google_compute_subnetwork.gcp_vcn_private_sn.id
  }
}