terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "3.8.2" # Adjust based on your NSX-T version
    }
  }
}

locals {
  secgroups_raw = jsondecode(file("${path.module}/secgroups.json"))

  /*secgroups_simplified = [
    for sgp in local.secgroups_raw : {
      name = sgp.display_name
      sgp_expression = [
        for entry in sgp.expression : {
          key               = lookup(entry, "key", null)
          value             = lookup(entry, "value",null)
          operator          = lookup(entry, "operator",null)
          member_type       = lookup(entry, "member_type",null)
        }
      ]
    }
  ]*/

  secgroups_parsed = [
    for sg in local.secgroups_raw : {
      id          = sg.id
      name        = sg.display_name
      expressions = flatten([
        for e in sg.expression : (
          e.resource_type == "Condition" ? [{
            type        = "condition"
            key         = e.key
            value       = e.value
            operator    = e.operator
            member_type = e.member_type
          }] :
          e.resource_type == "ConjunctionOperator" ? [{
            type     = "conjunction"
            operator = e.conjunction_operator
          }] :
          e.resource_type == "NestedExpression" ? [
            for ne in e.expressions : (
              ne.resource_type == "Condition" ? {
                type        = "nested_condition"
                key         = ne.key
                value       = ne.value
                operator    = ne.operator
                member_type = ne.member_type
              } :
              ne.resource_type == "ConjunctionOperator" ? {
                type     = "nested_conjunction"
                operator = ne.conjunction_operator
              } : null
            )
          ] : []
        )
      ])
    }
  ]
}


resource "nsxt_policy_group" "sg" {
  for_each     = { for sg in local.secgroups_parsed : sg.id => sg }
  display_name = each.value.name
  domain = "cgw"
  #description  = "Imported from JSON"

  dynamic "criteria" {
    for_each = [for e in each.value.expressions : e if e.type == "condition" || e.type == "nested_condition"]  
    content {
      condition{
          key         = criteria.value.type == "condition" || criteria.value.type == "nested_condition" ? criteria.value.key : null
          value       = criteria.value.type == "condition" || criteria.value.type == "nested_condition" ? criteria.value.value : null
          operator    = criteria.value.type == "condition" || criteria.value.type == "nested_condition" ? criteria.value.operator : null
          member_type = criteria.value.type == "condition" || criteria.value.type == "nested_condition" ? criteria.value.member_type : null
      }
    }
  }
  dynamic "conjunction" {
    for_each = [for e in each.value.expressions : e if e.type == "conjunction" || e.type == "nested_conjunction"]
    content {
      operator = conjunction.value.operator
    }
  }
}


/*resource "nsxt_policy_group" "secgroupJSON" {
  for_each = {
    for sgp in local.secgroups_simplified : sgp.name => sgp
  }
  display_name = each.value.name
  domain = "cgw"
  dynamic "criteria" {
    for_each = each.value.expression
    content {
      condition{
        key         = criteria.value.key
        value       = criteria.value.value
        operator    = criteria.value.operator
        member_type = criteria.value.member_type
      }
    }
  }
}*/



###########the following is only for csv use#################
variable "secgroup_name" {
	type = string
}

variable "secgroup_description" {
	type = string
}

variable "virtual_machine_name" {
	type = string
}

variable "virtual_machine_tag" {
	type = string
}

variable "domain" {
  type = string
}

/*variable "expression" {
  type = list(object({
    type        = string
    key         = optional(string)
    value       = optional(string)
    operator    = optional(string)
    member_type = optional(string)
  }))
}*/

resource "nsxt_policy_group" "secgroupCSV" {
  display_name = var.secgroup_name
  description  = var.secgroup_description
  domain       = var.domain

  criteria {
    condition {
      key         = "Name"
      member_type = "VirtualMachine"
      operator    = "CONTAINS"
      value       = var.virtual_machine_name
    }
  }
}
