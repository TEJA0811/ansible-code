
variable "cluster_name" {
  type        = string
  description = "The name for the AKS resources created in the specified Azure Resource Group. This variable overwrites the 'prefix' var (The 'prefix' var will still be applied to the dns_prefix if it is set)"
}

variable "resource_group_name" {
  type        = string
  description = "resource group name"
}

variable "resource_group_location" {
  type        = string
  description = "resource group location"
}


variable "image_registry_server" {
  type        = string
  description = "Registry server which holds Identity Manager docker images"
}

variable "image_registry_server_username" {
  type        = string
  description = "Registry server username"
}

variable "image_registry_server_password" {
  type        = string
  description = "Registry server password"
  sensitive   = true
}



variable "kubernetes_version" {
  type = string
  description = "The Kubernetes version available in the region"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet where AKS will be deployed"
}

variable "os_disk_size_gb" {
  type = number
  description = "Disk size of nodes in GBs."
}

variable "sku_tier" {
  type = string
  description = "The SKU Tier that should be used for this Kubernetes Cluster. Possible values are Free and Paid"
}

variable "agents_pool_name" {
  type = string
  description = "The default Azure AKS agentpool (nodepool) name."
}

variable "agents_min_count" {
  type = number
  description = "Minimum number of nodes in a pool"
}


variable "agents_max_count" {
  type = number
  description = "Maximum number of nodes in a pool"
}

variable "agents_max_pods" {
  type = number
  description = "The maximum number of pods that can run on each agent."
}

variable "agents_type" {
  type = string
  description = "The type of Node Pool which should be created. Possible values are AvailabilitySet and VirtualMachineScaleSets."
}


variable "agents_size" {
  type = string
  description = "The default virtual machine size for the Kubernetes agents"
}

variable "kubernetes_namespace" {
  type = string
  description = "Indicates the namespace intended to be used in Kubernetes environment for Identity Manager Deployment"
}

variable "create_azure_pg_root_cert_secret" {
  type = bool
  description = ""
}

variable "keyvault_id" {
  type        = string
  description = "subnet[0] name"
}

variable "keyvault_tenent_id" {
  type        = string
  description = "subnet[0] name"
}

variable "common_tags" {
  default     = {}
  description = "Common Tags to apply on Azure Resources"
  type        = map(string)
}
