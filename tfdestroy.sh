#!/bin/bash

# Plan and deploy
terraform plan -destroy -out=tfdestroy
terraform apply -auto-approve tfdestroy

# Delete files
rm tfplan
rm tfdestroy
rm terraform.tfstate*
rm -fr .terraform
