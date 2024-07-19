# main.tf

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "agsubnet" {
  name                 = var.ag_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.ag_subnet_address
}

resource "azurerm_subnet" "pvlink_subnet" {
  name = var.pvlink_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name = azurerm_resource_group.rg.name
  address_prefixes = var.pvlink_subnet_address
  private_link_service_network_policies_enabled = false
  
}

resource "azurerm_network_security_group" "agw-nsg" {
  name                = "agw-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_subnet_network_security_group_association" "nsg-assoc" {
  subnet_id                 = azurerm_subnet.agsubnet.id
  network_security_group_id = azurerm_network_security_group.agw-nsg.id
}

locals {
  ag_inbound_ports_map = {
    "100" : "80",
    "110" : "443",
    "130" : "65200-65535"
  }
}

resource "azurerm_network_security_rule" "ag_nsg_rule_inbound" {
  for_each                    = local.ag_inbound_ports_map
  name                        = "Rule-Port-${each.value}"
  priority                    = each.key
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.agw-nsg.name
}


resource "azurerm_public_ip" "ag-pub-ip" {
  name                = var.public_ip_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_user_assigned_identity" "appag_umid" {
  name                = "appgw-umid"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}


# Resource-1: Azure Key Vault
resource "azurerm_key_vault" "keyvault" {
  name                            = var.key_vault_name
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  enabled_for_disk_encryption     = true
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days      = 7
  purge_protection_enabled        = false
  enabled_for_template_deployment = true
  sku_name                        = "premium"
}


# Resource-2: Azure Key Vault Default Policy
resource "azurerm_key_vault_access_policy" "key_vault_default_policy" {
  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  lifecycle {
    create_before_destroy = true
  }
  certificate_permissions = [
    "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"
  ]
  key_permissions = [
    "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"
  ]
  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]
  storage_permissions = [
    "Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"
  ]
}

# Resource-4: create or import the SSL certificate into Key Vault and store the certificate SID in a variable
resource "azurerm_key_vault_certificate" "my_cert_1" {
  depends_on   = [azurerm_key_vault_access_policy.key_vault_default_policy]
  name         = var.ssl_certificate_name
  key_vault_id = azurerm_key_vault.keyvault.id

  certificate_policy {
    issuer_parameters {
      name = "Unknown"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
    x509_certificate_properties {
      key_usage = [
        "digitalSignature",
        "keyEncipherment",
      "dataEncipherment"]
      subject            = "CN=example.com"
      validity_in_months = 12
    }
    lifetime_action {
      action {
        action_type = "EmailContacts"
      }
      trigger {
        days_before_expiry = 10
      }
    }
  }
}

/* resource "azurerm_key_vault_secret" "key_secret" {
  name         = var.key_vault_secret_name
  key_vault_id = azurerm_key_vault.keyvault.id
  value        = azurerm_key_vault_certificate.my_cert_1.id

} */

output "key_vault_url" {
  value = azurerm_key_vault.keyvault.vault_uri
}


resource "azurerm_application_gateway" "app_gtw" {
  name                = var.app_gateway_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name = var.sku_name
    tier = var.sku_tier

  }
  autoscale_configuration {
    min_capacity = 0
    max_capacity = 2
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.0"
  }

  gateway_ip_configuration {
    name      = var.gateway_ip_configuration_name
    subnet_id = azurerm_subnet.agsubnet.id
  }

  frontend_port {
    name = var.frontend_port_name_http
    port = 80
  }

  # Frontend Port  - HTTP Port 443
  frontend_port {
    name = var.frontend_port_name_https
    port = 443
  }

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.ag-pub-ip.id
  }

  backend_address_pool {
    name = var.backend_address_pool_name_app1
  }

  backend_http_settings {
    name                  = var.http_setting_name_app1
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = var.probe_name_app1
  }
  probe {
    name                = var.probe_name_app1
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Http"
    port                = 80
    path                = "/"
    match {
      body        = "app1"
      status_code = ["200"]
    }
  }

  # HTTP Listener - Port 80
  http_listener {
    name                           = var.listener_name_http
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = var.frontend_port_name_http
    protocol                       = "Http"
  }

  # HTTP Routing Rule - HTTP to HTTPS Redirect
  request_routing_rule {
    name                        = var.request_routing_rule_name100
    rule_type                   = "Basic"
    priority                    = "100"
    http_listener_name          = var.listener_name_http
    redirect_configuration_name = var.redirect_configuration_name

  }

  # Redirect Config for HTTP to HTTPS Redirect  
  redirect_configuration {
    name                 = var.redirect_configuration_name
    redirect_type        = "Permanent"
    target_listener_name = var.listener_name_https
    include_path         = true
    include_query_string = true
  }

  # HTTPS Listener - Port 443  
  http_listener {
    name                           = var.listener_name_https
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = var.frontend_port_name_https
    protocol                       = "Https"
    ssl_certificate_name           = var.ssl_certificate_name
  }

# HTTPS Routing Rule - Port 443
  request_routing_rule {
    name                       = var.request_routing_rule_name200
    rule_type                  = "Basic"
    priority                   = "200"
    http_listener_name         = var.listener_name_https
    backend_address_pool_name = var.backend_address_pool_name_app1
    backend_http_settings_name = var.http_setting_name_app1
  }

  ssl_profile {
    name = "ssl_profile-appgw"
  
   ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401"
   }
  }
  
  ssl_certificate {
    name     = var.ssl_certificate_name
    password = "kalyan"
    data     = filebase64("${path.module}/httpd.pfx")
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appag_umid.id]
  }

}

# Enable diagnostic logs for the Application Gateway

resource "azurerm_storage_account" "stg_acct" {
  name                     = "myactgtsfs011"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_log_analytics_workspace" "log_work_space" {
  name = "test-log-workspace1"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  
}

resource "azurerm_monitor_diagnostic_setting" "diag-appgw" {
  name               = "diag-appgw1"
  target_resource_id = azurerm_application_gateway.app_gtw.id
  storage_account_id = azurerm_storage_account.stg_acct.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_work_space.id

dynamic "enabled_log" {
    for_each = var.agw_diag_logs
    content {
      category = enabled_log.value
      
    }
  }

  metric {
    category = "AllMetrics"

  }

  lifecycle {
    ignore_changes = [log, metric]
  }
}

# Create Private Link service

resource "azurerm_private_link_service" "pvlink" {
  name                = "pvtl-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
#  load_balancer_frontend_ip_configuration_ids = [azurerm_application_gateway.app_gtw.frontend_ip_configuration[0].id]
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.example.frontend_ip_configuration[0].id]
  

  nat_ip_configuration {
    name = "nat-ip"
    private_ip_address = "10.10.110.10"
    subnet_id = azurerm_subnet.pvlink_subnet.id
    primary = true
  }
}

# create Private end Point
resource "azurerm_private_endpoint" "example" {
  name                = "appgw-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pvlink_subnet.id

  private_service_connection {
    name                           = "apgw-privateserviceconnection"
    private_connection_resource_id = azurerm_private_link_service.pvlink.id
#    subresource_names = azurerm_application_gateway.app_gtw
    is_manual_connection           = false
  }
}


resource "azurerm_lb" "example" {
  name                = "example-lb"
  sku                 = "Standard"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = azurerm_public_ip.example.name
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

resource "azurerm_public_ip" "example" {
  name                = "example-api"
  sku                 = "Standard"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}



