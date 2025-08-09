locals {
  segments  = csvdecode(file("${path.module}/modules/segment_template/segments.csv"))
  services  = csvdecode(file("${path.module}/modules/service_template/services.csv"))
  secgroups = csvdecode(file("${path.module}/modules/secgroup_template/secgroups.csv"))
}

module "segments" {
  source   = "./modules/segment_template/"
  for_each = { for seg in local.segments : seg.name => seg }
  #for_each = toset(local.string_list)

  name    = each.value.name
  vlan_id = each.value.vlan_id
  cidr    = each.value.cidr
  # transport_zone_id = each.value.transport_zone_id
}

module "services" {
  source   = "./modules/service_template"
  for_each = { for ser in local.services : ser.service_name => ser }

  service_name        = each.value.service_name
  service_description = each.value.service_description
  protocol            = each.value.protocol
  entry_name          = each.value.entry_name
  entry_description   = each.value.entry_description
  source_ports        = each.value.source_ports
  destination_ports   = each.value.destination_ports
}

module "secgroups" {
  source   = "./modules/secgroup_template"
  for_each = { for sec in local.secgroups : sec.secgroup_name => sec }

  secgroup_name        = each.value.secgroup_name
  secgroup_description = each.value.secgroup_description
  domain               = each.value.domain
  virtual_machine_name = each.value.virtual_machine_name
  virtual_machine_tag  = each.value.virtual_machine_tag
  #expression          = each.value.expression
}
