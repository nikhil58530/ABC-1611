Nikhil

Github repo link:-  https://github.com/nikhil58530/ABC-1611.git

5th  question


Main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.20.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-devops-demo"
  location = var.location
}

# NSG for VM1
resource "azurerm_network_security_group" "nsg_vm1" {
  name                = "nsg-vm1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NSG for VM2
resource "azurerm_network_security_group" "nsg_vm2" {
  name                = "nsg-vm2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowInternal"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.internal_cidr
    destination_address_prefix = var.internal_cidr
  }
}

# VNet1 (for public VM)
resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = [var.vnet1_address_space]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = [var.subnet1_prefix]
}

# VNet2 (for private VM)
resource "azurerm_virtual_network" "vnet2" {
  name                = "vnet2"
  address_space       = [var.vnet2_address_space]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet2" {
  name                 = "subnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = [var.subnet2_prefix]
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "assoc_subnet1" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg_vm1.id
}

resource "azurerm_subnet_network_security_group_association" "assoc_subnet2" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.nsg_vm2.id
}

# VNet Peering
resource "azurerm_virtual_network_peering" "peer1to2" {
  name                         = "peer-vnet1-to-vnet2"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet2.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "peer2to1" {
  name                         = "peer-vnet2-to-vnet1"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet1.id
  allow_virtual_network_access = true
}

# Public IP for VM1
resource "azurerm_public_ip" "vm1_public_ip" {
  name                = "vm1-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NIC for VM1
resource "azurerm_network_interface" "nic_vm1" {
  name                = "nic-vm1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vm1_private_ip
    public_ip_address_id          = azurerm_public_ip.vm1_public_ip.id
  }
}

# NIC for VM2
resource "azurerm_network_interface" "nic_vm2" {
  name                = "nic-vm2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vm2_private_ip
  }
}

# Public VM (VM1)
resource "azurerm_linux_virtual_machine" "vm1" {
  name                            = "vm-public"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username
  network_interface_ids           = [azurerm_network_interface.nic_vm1.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Private VM (VM2)
resource "azurerm_linux_virtual_machine" "vm2" {
  name                            = "vm-private"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username
  network_interface_ids           = [azurerm_network_interface.nic_vm2.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

---------------------------------------------------------
Terraform.tfvars

subscription_id     = "1d1879cd-7c93-4f97-b9eb-d7546b5a2066"
client_id           = "5d58be33-1ee7-4326-9eee-013ef2a5c5b0"
client_secret       = "Q6q8Q~brBj3gfBhjNtHVsLEGpgm9oc4J2txZ6bzp"
tenant_id           = "ae7b4c65-9e93-4d7f-95a3-1cdd01063a6f"

location            = "West US"

vnet1_address_space = "10.5.0.0/16"
vnet2_address_space = "10.15.0.0/16"

subnet1_prefix      = "10.5.1.0/24"
subnet2_prefix      = "10.15.1.0/24"

internal_cidr       = "10.0.0.0/8"

vm1_private_ip      = "10.5.1.4"
vm2_private_ip      = "10.15.1.4"

admin_username      = "azureuser"

ssh_public_key_path = "~/.ssh/id_rsa.pub"



variables.tf

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "client_id" {
  description = "Azure client (application) ID"
  type        = string
}

variable "client_secret" {
  description = "Azure client secret"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US"
}

variable "vnet1_address_space" {
  description = "Address space for VNet1"
  type        = string
  default     = "10.5.0.0/16"
}

variable "vnet2_address_space" {
  description = "Address space for VNet2"
  type        = string
  default     = "10.15.0.0/16"
}

variable "subnet1_prefix" {
  description = "Subnet prefix for subnet1 (VNet1)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet2_prefix" {
  description = "Subnet prefix for subnet2 (VNet2)"
  type        = string
  default     = "10.1.1.0/24"
}

variable "internal_cidr" {
  description = "Internal CIDR block for communication between VMs"
  type        = string
  default     = "10.0.0.0/8"
}

variable "vm1_private_ip" {
  description = "Static private IP for VM1 (public VM)"
  type        = string
  default     = "10.0.1.4"
}

variable "vm2_private_ip" {
  description = "Static private IP for VM2 (private VM)"
  type        = string
  default     = "10.1.1.4"
}

variable "admin_username" {
  description = "Admin username for both VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for VM login"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}


Terraform.init  and terraform.plan is shown
 ![image](https://github.com/user-attachments/assets/b677dbf6-39b6-49a7-9777-a4e13e2a719f)


![image](https://github.com/user-attachments/assets/1d107203-a2c3-40d9-9146-551c4ab2075f)




![image](https://github.com/user-attachments/assets/00878ba1-326f-486a-aff4-7aa1b25848ce)






 



 

Two vm got created

 

![image](https://github.com/user-attachments/assets/1e08d886-b7c6-4505-a146-345742ca7895)




















Entering in public vm 
 
![image](https://github.com/user-attachments/assets/7e58361e-fe19-4f82-a8c6-8edcbf351f23)



To  ensure peering is done in have made ping form vm_public  to vm_private
 
![image](https://github.com/user-attachments/assets/53318556-d36b-4373-b694-9282d5dec394)


Moving all files to github repo
 



![image](https://github.com/user-attachments/assets/16856ea9-3229-48f6-82e5-5796426beb96)








Created repo ABC-1611 and cloned it and pushed all the code in it by removing the secretes form it
 

![image](https://github.com/user-attachments/assets/282f9a07-fec3-4c1c-a054-f3c25172c1a5)











Module is created
 ![image](https://github.com/user-attachments/assets/36608938-1a9d-48b4-b0b2-344c2f5b1db6)


