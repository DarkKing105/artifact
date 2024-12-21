terraform {
  required_providers {
    proxmox = {
      #source = "registry.example.com/telmate/proxmox"
      source = "Telmate/proxmox"
      version = ">=1.0.0"
    }
  }
  required_version = ">= 0.14"
}

provider "proxmox" {
    pm_api_url          = "https://192.168.0.112:8006/api2/json"
    pm_api_token_id     = "terraform@pam!terraform"
    pm_api_token_secret = "3c7155ff-1754-4f6e-a2fc-fbb9969181a5"
    pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "k3s-master" {
    target_node = "vmnode"
    desc = "Cloudinit"
    count = 2
    onboot = true
    startup = true
    clone = "ubuntu-master"
    agent = 1
    os_type = "cloud-init"
    cores = 2
    sockets = 2
    numa = true
    vcpus = 0
    cpu = "x86-64-v2-AES"
    memory = 4096
    name = "k3s-master-${count.index + 1}"

    cloudinit_cdrom_storage = "local-lvm"
    scsihw   = "virtio-scsi-single" 
    bootdisk = "scsi0"

    disk {
        type    = "scsi"
        storage = "local-lvm"
        size    = "12G"
    }

    
    ipconfig0 = "ip=192.168.0.13${count.index + 1}/24,gw=192.168.0.1"
    ciuser = "ubuntu"
    sshkeys = <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCTAQVXCAhsYj6P7n32gH7ASMbvK4bgkLW9giJECnczn/NpGcWo0cKm+8aoxfBTM5xiYPp7TP4QF3WA0BpVI00Ac+1UJmylgs5H/SNEROwEdSRrjIw06NvmOUx+n/TIeHd8eGMA0he/ZM9Qa9O02e1eCJbkiPH98gu5TGoyLScsdooF4TQ+gXSw0s7v9ZOvZ6n+w2chDQ3KmcAYHlCMhXe+VXnNlqq0oMiHyG3PlLX1sWGQpHsVxfisSfMUkhXKZPAy0lTf5+/8trMk1TCjV2j1Ht9a8AS7hzMD1NoJFtrRBTZjf81CqNV9kbfYKzlzlVK7BXXkslt6/HQ6cspdWIB7vTLANaMi/TdSM8owHkmUvtzbzl8rPFaJAMhda/FX4TbCNpEnNbUzDzpRVgornIKmbzvbPnTzaco9zo6DzKKiVzCouNDXfBlK5y6EoEdnlpdn+Y/VUPkCOSoiwF/67BV1rvbWOYnUdKjr9heHreVGIGvEfO5MkkoSRwOLjVKnDscZnudndjexUfoTF2Y08y5lTiHbO3LlAxQNjatGum9o8YyQPew9/Ztbmpko6y9hcG2o/nL2ysQ08UWdRYEWYmr5DdEbvOAMaOndU0bCljP/MoZbTfI9qm176lmvIoVkyXBM2zHr2QPRfsDe+wKyNd9Y24wQmzIpEpX6LoWhkLw1Nw== root@asus
    EOF
}

resource "proxmox_vm_qemu" "k3s-worker" {

    target_node = "vmnode"
    desc = "Cloudinit"
    count = 2
    onboot = true
    clone = "ubuntu-cloud"
    startup = true
    agent = 1

    os_type = "cloud-init"
    cores = 2
    sockets = 2
    numa = true
    vcpus = 0
    cpu = "x86-64-v2-AES"
    memory = 4096
    name = "k3s-worker-${count.index + 1}"

    cloudinit_cdrom_storage = "local-lvm"
    scsihw   = "virtio-scsi-single" 
    bootdisk = "scsi0"

    disk {
        type    = "scsi"
        storage = "local-lvm"
        size    = "12G"
    }

    ipconfig0 = "ip=192.168.0.14${count.index + 1}/24,gw=192.168.0.1"
    ciuser = "ubuntu"
    sshkeys = <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCTAQVXCAhsYj6P7n32gH7ASMbvK4bgkLW9giJECnczn/NpGcWo0cKm+8aoxfBTM5xiYPp7TP4QF3WA0BpVI00Ac+1UJmylgs5H/SNEROwEdSRrjIw06NvmOUx+n/TIeHd8eGMA0he/ZM9Qa9O02e1eCJbkiPH98gu5TGoyLScsdooF4TQ+gXSw0s7v9ZOvZ6n+w2chDQ3KmcAYHlCMhXe+VXnNlqq0oMiHyG3PlLX1sWGQpHsVxfisSfMUkhXKZPAy0lTf5+/8trMk1TCjV2j1Ht9a8AS7hzMD1NoJFtrRBTZjf81CqNV9kbfYKzlzlVK7BXXkslt6/HQ6cspdWIB7vTLANaMi/TdSM8owHkmUvtzbzl8rPFaJAMhda/FX4TbCNpEnNbUzDzpRVgornIKmbzvbPnTzaco9zo6DzKKiVzCouNDXfBlK5y6EoEdnlpdn+Y/VUPkCOSoiwF/67BV1rvbWOYnUdKjr9heHreVGIGvEfO5MkkoSRwOLjVKnDscZnudndjexUfoTF2Y08y5lTiHbO3LlAxQNjatGum9o8YyQPew9/Ztbmpko6y9hcG2o/nL2ysQ08UWdRYEWYmr5DdEbvOAMaOndU0bCljP/MoZbTfI9qm176lmvIoVkyXBM2zHr2QPRfsDe+wKyNd9Y24wQmzIpEpX6LoWhkLw1Nw== root@asus
    EOF
}