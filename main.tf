terraform {
  required_version = ">= 1.6"
  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = "~> 2.13"
    }
  }
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "HomeLab"
}

data "vsphere_host" "esxi" {
  name          = "192.168.100.11"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_host_port_group" "lab_net" {
  name                = "LabNetwork"
  virtual_switch_name = "vSwitch0"
  vlan_id             = 0
  host_system_id      = data.vsphere_host.esxi.id
}

data "vsphere_network" "lab_net" {
  name          = vsphere_host_port_group.lab_net.name
  datacenter_id = data.vsphere_datacenter.dc.id
  depends_on    = [vsphere_host_port_group.lab_net]
}

data "vsphere_resource_pool" "pool" {
  name          = "192.168.100.11/Resources"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "ds" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "Server_Template_1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "demo_vm" {
  name             = "DemoVM"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.ds.id

  num_cpus = 2
  memory   = 2048
  guest_id = data.vsphere_virtual_machine.template.guest_id

  network_interface {
    network_id   = data.vsphere_network.lab_net.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = 20
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      windows_options {
        computer_name         = "DEMOVM"
        admin_password        = "Ectothermia995?"
        time_zone             = 35
        auto_logon            = true
        auto_logon_count      = 1
        run_once_command_list = [
          "powershell -Command \"Set-ExecutionPolicy RemoteSigned -Force\""
        ]
      }

      network_interface {
        ipv4_address    = "192.168.100.50"
        ipv4_netmask    = 24
        dns_server_list = ["192.168.100.1"]
      }
      ipv4_gateway = "192.168.100.1"
    }
  }
}

variable "vsphere_user"     { type = string }
variable "vsphere_password" { type = string }
variable "vsphere_server"   { type = string }
