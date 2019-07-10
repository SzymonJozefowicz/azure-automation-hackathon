#==============================================================================================
#
#                                  VARIABLES
#
#==============================================================================================

#Provide Id of Azure subscription
variable "SUBSCRIPTION_ID" {}
variable "ADMIN_USERNAME" {}
variable "ADMIN_PASSWORD" {}
variable "PREFIX" {}
variable "RESOURCE_GROUP" {}


#Name of resource group where resources will be created


#Location where resource will be created
variable "location" {
  description = "The Azure Region in which the resources in this example should exist"
  default="westeurope"
}

#Name of resource group with virtual network
variable "network_resource_group" {
  description = "The Azure Network Resource group"
  default="eur-infra-net-rg"
}

#Name of virtual network
variable "network_name" {
  description = "The Azure Netowrk name"
  default="eur-infra-dev-test-vnet"
}

#Name of virtual network subnet
variable "network_subnet" {
  description = "The Azure Netowrk subnet"
  default="sandbox3"
}

#Global tags which will be assigned to all resources
variable "tags" {
  type        = "map"
  default = {
      Project = "Azure Automation Hackathon"
      Application = "Azure Automation Hackathon"
      Owner="Szymon Jozefowicz"
      Environment= "Development"
    }
  description = "Any tags which should be assigned to the resources in this example"
}





#==============================================================================================
#
#                                  LOCALS DEFINITION
#
#==============================================================================================

#Local values
locals {
  subscription_id       = "${var.SUBSCRIPTION_ID}"
  virtual_machine_name  = "${var.PREFIX}"
  admin_username        = "${var.ADMIN_USERNAME}"
  admin_password        = "${var.ADMIN_PASSWORD}"
  prefix		            = "${var.PREFIX}"
  resource_group	      = "${var.RESOURCE_GROUP}"

}

#==============================================================================================
#
#                      AZURE PROVIDER AND SUBSCRIPTION DEFINITION
#
#==============================================================================================

provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  subscription_id = "${var.SUBSCRIPTION_ID}"
}
data "azurerm_subscription" "current" {}
output "current_subscription_display_name" {
  value = "${data.azurerm_subscription.current.display_name}"
}



#==============================================================================================
#
#                               RESOURCE GROUP DEFINIITION
#
#==============================================================================================

resource "azurerm_resource_group" "resource_group" {
  name     = "${local.resource_group}"
  location = "${var.location}"
  tags     = "${var.tags}"
}

output "resource_group_name" {
  value = "${azurerm_resource_group.resource_group.name}"
}

#==============================================================================================
#
#                  NETWORK CONFIGURATION FROM EXISTING RESOURCE GROUP
#
#==============================================================================================

# Get network resource group
data "azurerm_resource_group" "network_resource_group" {
  name = "${var.network_resource_group}"
}
output "network_resource_group_name" {
  value = "${data.azurerm_resource_group.network_resource_group.name}"
}


#Get subnet
data "azurerm_subnet" "network_subnet" {
  name                 = "${var.network_subnet}"
  virtual_network_name = "${var.network_name}"
  resource_group_name  = "${var.network_resource_group}"
}
output "subnet_name" {
  value = "${data.azurerm_subnet.network_subnet.name}"
}




#==============================================================================================
#                                           NETWORK SECURITY GROUP
#==============================================================================================

resource "azurerm_network_security_group" "nsg" {
  name                  = "${local.virtual_machine_name}-nsg"
  location              = "${azurerm_resource_group.resource_group.location}"
  resource_group_name   = "${azurerm_resource_group.resource_group.name}"
  tags     = "${var.tags}"
}


#==============================================================================================
#                                           NETWORK INTERFACE SETUP
#==============================================================================================


# create a network interface
resource "azurerm_network_interface" "vmnic" {
  count               = 3
  name                = "${local.prefix}-${count.index}-nic"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  network_security_group_id="${azurerm_network_security_group.nsg.id}"

  ip_configuration {
    name                          = "ipconfiguration1"
    subnet_id                     = "${data.azurerm_subnet.network_subnet.id}"
    private_ip_address_allocation = "Dynamic"
      }
  tags = "${var.tags}"
}



#==============================================================================================
#
#                  VIRTUAL MACHINE CONFIGURATION ON NEW RESOURCE GROUP
#
#==============================================================================================


resource "azurerm_virtual_machine" "vm" {
  count                 = 3
  name                  = "${local.virtual_machine_name}-${count.index}"
  location              = "${azurerm_resource_group.resource_group.location}"
  resource_group_name   = "${azurerm_resource_group.resource_group.name}"
  #network_interface_ids = "${azurerm_network_interface.vmnic[count.index]}"
  network_interface_ids = ["${element(azurerm_network_interface.vmnic.*.id, count.index)}"]
  vm_size               = "Standard_B1s"
  
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

    storage_image_reference {
        publisher = "Canonical"
    	  offer     = "UbuntuServer"
    	  sku       = "18.04-LTS"
	      version = "latest"
    }

  storage_os_disk {
    name              = "${local.virtual_machine_name}-${count.index}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
   
  }
  

  os_profile {
    computer_name  = "${local.virtual_machine_name}-${count.index}"
    admin_username = "${local.admin_username}"
    admin_password = "${local.admin_password}"
    
  }

os_profile_linux_config {
        disable_password_authentication = false
        #ssh_keys {
        #    path     = "/home/${local.admin_username}/.ssh/authorized_keys"
	      #    key_data = "${var.ssh_public_key}"
        #}
    }


  tags = "${var.tags}"
}

output "vms_name" {
  value = "${azurerm_virtual_machine.vm.*.name}"
}

output "private_ip_addresses" {
  value = "${azurerm_network_interface.vmnic.*.private_ip_address}"
}


#==============================================================================================
#                                     AUTOMATION ACCOUNT
#==============================================================================================

resource "azurerm_automation_account" "aa" {
  name                = "${local.prefix}-aa"
  location            = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  sku_name	      = "Basic"
  tags = "${var.tags}"
}

output "aa_name" {
  value = "${azurerm_automation_account.aa.name}"
}



resource "azurerm_automation_schedule" "one-time" {
  name                    = "${local.prefix}-one-time"
  resource_group_name     = "${azurerm_resource_group.resource_group.name}"
  automation_account_name = "${azurerm_automation_account.aa.name}"
  frequency               = "OneTime"
    // The start_time defaults to now + 7 min
}

resource "azurerm_automation_schedule" "hour" {
  name                    = "${local.prefix}-hour"
  resource_group_name     = "${azurerm_resource_group.resource_group.name}"
  automation_account_name = "${azurerm_automation_account.aa.name}"
  frequency               = "Hour"
  interval                = 1
    // Timezone defaults to UTC
}

#==============================================================================================
#                                     LOGIC APP
#==============================================================================================

resource "azurerm_logic_app_workflow" "example" {
  name                = "${local.prefix}-logicapp"
  location            = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  tags = "${var.tags}"
}

output "la_name" {
  value = "${azurerm_logic_app_workflow.example.name}"
}


resource "azurerm_logic_app_trigger_recurrence" "hourly" {
  name         = "run-every-hour"
  logic_app_id = "${azurerm_logic_app_workflow.example.id}"
  frequency    = "Hour"
  interval     = 1
 }

resource "azurerm_logic_app_action_http" "main" {
  name         = "clear-stale-objects"
  logic_app_id = "${azurerm_logic_app_workflow.example.id}"
  method       = "DELETE"
  uri          = "http://example.com/clear-stable-objects"
 }


#==============================================================================================
#                                           END OF CODE
#==============================================================================================
