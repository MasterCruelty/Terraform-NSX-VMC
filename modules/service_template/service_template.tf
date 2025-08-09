terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "3.8.2" # Adjust based on your NSX-T version
    }
  }
}

locals {
  services_raw = jsondecode(file("${path.module}/services.json"))

  services_simplified = [
    for svc in local.services_raw : {
      name = svc.display_name
      entries = [
        for entry in svc.service_entries : {
          display_name      = entry.display_name
          l4_protocol       = lookup(entry, "l4_protocol", null)
          source_ports      = lookup(entry, "source_ports", [])
          destination_ports = lookup(entry, "destination_ports", [])
        }
      ]
    }
  ]
}

resource "nsxt_policy_service" "service_json" {
  for_each = {
    for svc in local.services_simplified : svc.name => svc
  }
  display_name = each.value.name
  dynamic "l4_port_set_entry" {
    for_each = each.value.entries
    content {
      display_name      = l4_port_set_entry.value.display_name
      protocol          = l4_port_set_entry.value.l4_protocol
      source_ports      = l4_port_set_entry.value.source_ports
      destination_ports = l4_port_set_entry.value.destination_ports
    }

  }
}

variable "service_name" {
        type = string
}

variable "service_description" {
        type = string
}

variable "entry_name" {
    type = string
}
variable "entry_description" {
        type = string
}

variable "protocol" {
        type = string
}

variable "source_ports" {
	type = string
}

variable "destination_ports" {
	type = string
}


resource "nsxt_policy_service" "service_csv" {

  description  = var.service_description
  display_name = var.service_name

  l4_port_set_entry {
    display_name      = var.entry_name
    description       = var.entry_description
    protocol          = var.protocol
    destination_ports = split(";",var.destination_ports)
    source_ports = split(";",var.source_ports)
  }
}