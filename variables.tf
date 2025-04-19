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
