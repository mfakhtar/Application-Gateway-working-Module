# outputs.tf

output "application_gateway_id" {
  description = "The ID of the created Application Gateway."
  value       = azurerm_application_gateway.app_gtw.id
}

output "application_gateway_backend_address" {
  description = "The backend address of the Application Gateway."
  value       = azurerm_application_gateway.app_gtw.backend_address_pool
}


# Output Values for manageed Identity

output "user_assigned_identity_id" {
  value = azurerm_user_assigned_identity.appag_umid.id
}
output "user_assigned_identity_principal_id" {
  value = azurerm_user_assigned_identity.appag_umid.principal_id
}
output "user_assigned_identity_client_id" {
  value = azurerm_user_assigned_identity.appag_umid.client_id
}
output "user_assigned_identity_tenant_id" {
  value = azurerm_user_assigned_identity.appag_umid.tenant_id
}

# output values for Key Vault 

output "azurerm_key_vault_certificate_id" {
  value = azurerm_key_vault_certificate.my_cert_1.id
}

output "azurerm_key_vault_certificate_secret_id" {
  value = azurerm_key_vault_certificate.my_cert_1.secret_id
}
output "azurerm_key_vault_certificate_version" {
  value = azurerm_key_vault_certificate.my_cert_1.version
}





