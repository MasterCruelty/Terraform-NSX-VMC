terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "3.8.2" # Adjust based on your NSX-T version
    }
  }
}

variable "name" {
        type = string
}

variable "vlan_id" {
        type = string
}

variable "cidr" {
        type = string
}

#variable "transport_zone_id" {
#       type = string
#}

#data "nsxt_policy_transport_zone" "overlay_tz" {
 # display_name = var.transport_zone_id
#}

data "nsxt_policy_tier1_gateway" "t1_demo" {
  display_name = "demo"
}

data "nsxt_policy_tier1_gateway" "t1_destname"{
  display_name = "t1-dest-name"
}

locals {
  demo_segments = [
    "segment-demo-01",
    "segment-demo-02",
    "segment-demo-03",
    "segment-demo-04",
    "segment-demo-05"
  ]
}

resource "nsxt_policy_fixed_segment" "this" {
        display_name = var.name
        vlan_ids = [var.vlan_id]
        #transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
        connectivity_path = contains(local.demo_segments, var.name) ? data.nsxt_policy_tier1_gateway.t1_demo.path : data.nsxt_policy_tier1_gateway.t1_destname.path
        subnet {
                cidr = var.cidr # static CIDR
                #cidr = "10.250.${index(var.logical_segments, each.value) + 1}.1/24" # Example dynamic CIDR
    }
}
