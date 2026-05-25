
# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
   }
  }
}

# Create a resource group
resource "azurerm_resource_group" "app_rg" {
  name     = "reactapp_rg"
  location = ""                                          #Insert Username
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "app_vnet" {
  name                = "reactapp_vnet"
  resource_group_name = azurerm_resource_group.app_rg.name 
  location            = azurerm_resource_group.app_rg.location
  address_space       = ["10.0.0.0/16"]
}

# Create a subnet within the virtual network and resource group
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.app_rg.name
  virtual_network_name = azurerm_virtual_network.app_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create a public ip for internet access
resource "azurerm_public_ip" "app_ip" {
  name                = "appvm_ip"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = azurerm_resource_group.app_rg.location
  allocation_method   = "Static"
}

# Create a NIC for the vm networking
resource "azurerm_network_interface" "vm_nic" {
  name                = "reactapp_nic"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name

  ip_configuration {
    name                          = "appvmprivate_ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.app_ip.id
  }
}

resource "azurerm_network_security_group" "web_sg" {
  name                = "allowHTTPandSSH"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

# Create a virtual machine
resource "azurerm_virtual_machine" "app_vm" {
  name                = "reactapp-vm"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = azurerm_resource_group.app_rg.location
  vm_size                = "Standard_D2ls_v5"
  network_interface_ids = [azurerm_network_interface.vm_nic.id]


  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "reactapp-vm"
    admin_username = ""                         #Insert Username
    admin_password = ""                         #Insert Password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.web_sg.id
}


output "vm_public_ip" {
  description = "Public IP Adrress"
  value       = azurerm_public_ip.app_ip.ip_address
}

