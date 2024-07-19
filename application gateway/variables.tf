
variable "resource_group_name" {
  description = "The name of the resource group in which to create the Application Gateway."
  type        = string
}

variable "location" {
  description = "The Azure region where the Application Gateway will be deployed."
  type        = string
}

variable "app_gateway_name" {
  description = "The name of the Application Gateway."
  type        = string
}

variable "sku_name" {
  description = "The name of the SKU for the Application Gateway (Standard_v2, WAF_v2, etc.)."
  type        = string
}

variable "sku_tier" {
  description = "The tier of the SKU for the Application Gateway (Standard, WAF, etc.)."
  type        = string
}

variable "vnet_name" {
  description = "Name of the vNet"
  type        = string
}

variable "vnet_address_space" {
  description = "this will be my vnet address space"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "ag_subnet_name" {
  description = "Virtual Network Application Gateway Subnet Name"
  type        = string
}

variable "ag_subnet_address" {
  description = "Virtual Network Application Gateway Subnet Address Spaces"
  type        = list(string)
  default     = ["10.10.100.0/24"]
}

variable "public_ip_name" {
  description = "this will be public IP address"
  type        = string
}

variable "frontend_port_name_http" {
  type = string

}
variable "frontend_port_name_https" {
  type = string

}

variable "frontend_ip_configuration_name" {
  type = string

}
variable "listener_name_http" {
  type = string

}
variable "listener_name_https" {
  type = string

}

variable "request_routing_rule_name100" {
  type = string
}

variable "request_routing_rule_name200" {
  type = string
}

variable "backend_address_pool_name_app1" {
  type = string

}
variable "http_setting_name_app1" {
  type = string

}
variable "probe_name_app1" {
  type = string

}
variable "gateway_ip_configuration_name" {
  type = string

}

variable "redirect_configuration_name" {
  type = string

}

variable "ssl_certificate_name_keyvault" {
  type = string

}
variable "ssl_certificate_name" {
  type = string

}
variable "key_vault_name" {
  type = string

}
variable "key_vault_secret_name" {
  type = string
}

variable "pvlink_subnet_name" {
  type = string
  
}
variable "pvlink_subnet_address" {
  type = list(string)
  
}

variable "agw_diag_logs" {
  description = "Application Gateway Monitoring Category details for Azure Diagnostic setting"
  type = list(string)
  default     = ["ApplicationGatewayAccessLog", "ApplicationGatewayPerformanceLog", "ApplicationGatewayFirewallLog"]
}




