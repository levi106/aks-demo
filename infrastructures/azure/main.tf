terraform {
    backend "azurerm" {
        resource_group_name = "#{BACKEND_RESOURCE_GROUP}#"
        storage_account_name = "#{BACKEND_STORAGE_ACCOUNT}#"
        container_name = "#{BACKEND_CONTAINER_NAME}#"
        key = "prod.terraform.tfstate"
    }
}

resource "azurerm_resource_group" "aks" {
    name = var.resource_group
    location = "japaneast"
}

resource "azurerm_log_analytics_workspace" "aks" {
    name = "${var.cluster_name}-law"
    resource_group_name = azurerm_resource_group.aks.name
    location = azurerm_resource_group.aks.location
    sku = "PerGB2018"
}

resource "azurerm_virtual_network" "aks" {
    name = "${var.cluster_name}-network"
    location = azurerm_resource_group.aks.location
    resource_group_name = azurerm_resource_group.aks.name
    address_space = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "default" {
    name = "default"
    virtual_network_name = azurerm_virtual_network.aks.name
    resource_group_name = azurerm_resource_group.aks.name
    address_prefixes = ["10.1.0.0/22"]
}

resource "azurerm_kubernetes_cluster" "aks" {
    name = var.cluster_name
    location = azurerm_resource_group.aks.location
    resource_group_name = azurerm_resource_group.aks.name
    dns_prefix = var.cluster_name

    default_node_pool {
        name = "default"
        node_count = 1
        vm_size = "Standard_D2_v2"
        vnet_subnet_id = azurerm_subnet.default.id
    }

    identity {
        type = "SystemAssigned"
    }

    network_profile {
        network_plugin = "azure"
    }

    addon_profile {
        aci_connector_linux {
            enabled = false
        }

        azure_policy {
            enabled = false
        }

        http_application_routing {
            enabled = false
        }

        kube_dashboard {
            enabled = false
        }

        oms_agent {
            enabled = true
            log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
        }
    }
}
