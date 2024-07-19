# main.tf in your deployment directory

module "app_gateway" {
  source                         = "./application gateway"
  resource_group_name            = "app1-web-rg1"
  location                       = "East US"
  vnet_name                      = "my_vnet1"
  vnet_address_space             = ["10.10.0.0/16"]
  ag_subnet_name                 = "appgateway1"
  ag_subnet_address              = ["10.10.100.0/28"]
  pvlink_subnet_name             = "pvlink-agw"
  pvlink_subnet_address          = ["10.10.110.0/28"]
  public_ip_name                 = "my-public1"
  app_gateway_name               = "webappgw001"
  sku_name                       = "WAF_v2"
  sku_tier                       = "WAF_v2"
  frontend_port_name_http        = "frontend-http-port1"
  frontend_port_name_https       = "frontend-https-port1"
  frontend_ip_configuration_name = "app1-front-ip-config1"
  listener_name_http             = "app1-http-listner1"
  listener_name_https            = "app1-https-listner1"
  request_routing_rule_name100   = "app1-rt-rule11"
  request_routing_rule_name200   = "app1-rt-rule12"
  backend_address_pool_name_app1 = "app1-backend-pool1"
  http_setting_name_app1         = "app1-http-settings1"
  probe_name_app1                = "app1-probe1"
  gateway_ip_configuration_name  = "app1-gw-ip1"
  ssl_certificate_name_keyvault  = "keyvault-my-cert-10"
  redirect_configuration_name    = "http-https_redirection1"
  ssl_certificate_name           = "my-cert-10"
  key_vault_name                 = "test-keeevault-786509711"
  key_vault_secret_name          = "app-secret10"
}
