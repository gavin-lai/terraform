#--------------------------------------------------#
# Variables for Web Server VM Count & Region       #
#--------------------------------------------------#

variable "web_vm_count" {}
variable "region" {}
variable "vnet_address_space" {
  default = "10.0.0.0/16"
}
variable "dmz_address_prefix" {
  default = "10.0.1.0/24"
}
variable "management_address_prefix" {
  default = "10.0.2.0/24"
}

#--------------------------------------------------#
# Configure the Azure Subscription Details         #
#--------------------------------------------------#

# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = ""
  client_id       = ""
  client_secret   = ""
  tenant_id       = ""
}

#------------------------------------------------------------------#
# Create random name and hex for generating unique service names   #
#------------------------------------------------------------------#

# Create random_id for use throughout the plan
resource "random_id" "random_name" {
  prefix      = "prodbdas"
  byte_length = "4"
}

#---------------------------------------------#
# Create Resource Group                       #
#---------------------------------------------#

# Create a resource group
resource "azurerm_resource_group" "production" {
  name     = "${lower(random_id.random_name.hex)}"
  location = "${var.region}"
}

#-------------------------------------#
# Create Network Components:          #
# 1. Virtual Network & Subnets        #
# 2. Network Security Groups          #
# 3. Load Balancer                    #
# 4. Network Interfaces               #
# 5. Public IPs                       #
#-------------------------------------#

# Create a virtual network in the production resource group
resource "azurerm_virtual_network" "prodvnet" {
  name                = "productionNetwork"
  address_space       = ["${var.vnet_address_space}"]
  location            = "${azurerm_resource_group.production.location}"
  resource_group_name = "${azurerm_resource_group.production.name}"
}

  resource "azurerm_subnet" "dmz" {
  name                      = "dmzsubnet"
  resource_group_name       = "${azurerm_resource_group.production.name}"
  virtual_network_name      = "${azurerm_virtual_network.prodvnet.name}"
  address_prefix            = "${var.dmz_address_prefix}"
  network_security_group_id = "${azurerm_network_security_group.prodwebnsg.id}"
}

  resource "azurerm_subnet" "mgmt" {
  name                      = "mgmtsubnet"
  resource_group_name       = "${azurerm_resource_group.production.name}"
  virtual_network_name      = "${azurerm_virtual_network.prodvnet.name}"
  address_prefix            = "${var.management_address_prefix}"
  network_security_group_id = "${azurerm_network_security_group.mgmtnsg.id}"
}

# create NSG for DMZ
resource "azurerm_network_security_group" "prodwebnsg" {
  name                = "prodwebnsg"
  location            = "${azurerm_resource_group.production.location}"
  resource_group_name = "${azurerm_resource_group.production.name}"

  security_rule {
    name                       = "allowbastionssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${var.management_address_prefix}"
    destination_address_prefix = "${var.dmz_address_prefix}"
  }

  tags {
    environment = "Production"
  }
}

# create NSG for Mgmt
resource "azurerm_network_security_group" "mgmtnsg" {
  name                = "mgmtnsg"
  location            = "${azurerm_resource_group.production.location}"
  resource_group_name = "${azurerm_resource_group.production.name}"

  security_rule {
    name                       = "allowinboundssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "Production"
  }
}

# Create Network Load Balancer Public IP
resource "azurerm_public_ip" "nlbpip" {
  name                         = "prodwebnlbpubip"
  location                     = "${azurerm_resource_group.production.location}"
  resource_group_name          = "${azurerm_resource_group.production.name}"
  public_ip_address_allocation = "Static"
  domain_name_label            = "bdasprodwebnlb"
}

# Create public IP for Bastion Host
resource "azurerm_public_ip" "bastionpublicip" {
  name                         = "bastionpubip-${format("%02d", count.index+1)}"
  location                     = "${azurerm_resource_group.production.location}"
  resource_group_name          = "${azurerm_resource_group.production.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "ctl-${lower(random_id.random_name.hex)}"

  tags {
    environment = "Production"
  }
}

# Create load balancer
resource "azurerm_lb" "weblb" {
  name                        = "prodwebnlb"
  resource_group_name         = "${azurerm_resource_group.production.name}"
  location                    = "${azurerm_resource_group.production.location}"

  frontend_ip_configuration {
  name                 = "prodwebnlbfe"
  public_ip_address_id = "${azurerm_public_ip.nlbpip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name                = "prodwebbackend"
  resource_group_name = "${azurerm_resource_group.production.name}"
  loadbalancer_id     = "${azurerm_lb.weblb.id}"
}

resource "azurerm_lb_probe" "prodweblbprobe" {
  resource_group_name = "${azurerm_resource_group.production.name}"
  loadbalancer_id     = "${azurerm_lb.weblb.id}"
  name                = "http-probe"
  port                = 80
}

resource "azurerm_lb_rule" "prodweblbrule" {
  resource_group_name            = "${azurerm_resource_group.production.name}"
  loadbalancer_id                = "${azurerm_lb.weblb.id}"
  name                           = "HTTPRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "prodwebnlbfe"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.backend_pool.id}"
  probe_id                       = "${azurerm_lb_probe.prodweblbprobe.id}"
}

# Create Web Servers NICs
resource "azurerm_network_interface" "prodwebnic" {
  count               = "${var.web_vm_count}"
  name                = "prodwebnics-${format("%02d", count.index+1)}"
  location            = "${azurerm_resource_group.production.location}"
  resource_group_name = "${azurerm_resource_group.production.name}"

  ip_configuration {
    name                                    = "dmzfe"
    subnet_id                               = "${azurerm_subnet.dmz.id}"
    private_ip_address_allocation           = "dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.backend_pool.id}"]
  }
}

# Create Bastion Host NIC
resource "azurerm_network_interface" "bastionnic" {
  name                = "bastionnic-${format("%02d", count.index+1)}"
  location            = "${azurerm_resource_group.production.location}"
  resource_group_name = "${azurerm_resource_group.production.name}"

  ip_configuration {
    name                                    = "mgmtfe"
    subnet_id                               = "${azurerm_subnet.mgmt.id}"
    private_ip_address_allocation           = "dynamic"
    public_ip_address_id                    = "${azurerm_public_ip.bastionpublicip.id}"
  }
}

#---------------------------------------------#
# Create Infrastructure Compute Components:   #
# 1. Web Servers Managed Availability Set     #
# 2. Web Server Virtual Machines              #
# 3. Bastion Host Virtual Machine             #
#---------------------------------------------#

# Create an availability set for web servers
resource "azurerm_availability_set" "prodwebservers" {
  name                = "webavailabilityset"
  location            = "${azurerm_resource_group.production.location}"
  resource_group_name = "${azurerm_resource_group.production.name}"
  managed             = "true"

  tags {
    environment = "Production"
  }
}

# Create Web VMs
resource "azurerm_virtual_machine" "webprodvm" {
  count                 = "${var.web_vm_count}"
  name                  = "webprodvm-${format("%02d", count.index+1)}"
  location              = "${azurerm_resource_group.production.location}"
  resource_group_name   = "${azurerm_resource_group.production.name}"
  network_interface_ids = ["${element(azurerm_network_interface.prodwebnic.*.id, count.index)}"]
  vm_size               = "Standard_DS1_v2"
  availability_set_id   = "${azurerm_availability_set.prodwebservers.id}"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "webosdisk-${format("%02d", count.index+1)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "webprodvm-${format("%02d", count.index+1)}"
    admin_username = "demouser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "production"
  }
}

# Create Bastion VM
resource "azurerm_virtual_machine" "bastionvm" {
  name                  = "bastionvm-${format("%02d", count.index+1)}"
  location              = "${azurerm_resource_group.production.location}"
  resource_group_name   = "${azurerm_resource_group.production.name}"
  network_interface_ids = ["${element(azurerm_network_interface.bastionnic.*.id, count.index)}"]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "bastionosdisk-${format("%02d", count.index+1)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "bastionvm-${format("%02d", count.index+1)}"
    admin_username = "demouser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "production"
  }
}

#---------------------------------------------#
# Create Azure SQL Database Services:         #
# 1. Azure SQL Server                         #
# 2. Azure SQL Database                       #
#---------------------------------------------#

# Create SQL Server
resource "azurerm_sql_server" "mssqlserver" {
  name                         = "${lower(random_id.random_name.hex)}"
  resource_group_name          = "${azurerm_resource_group.production.name}"
  location                     = "${azurerm_resource_group.production.location}"
  version                      = "12.0"
  administrator_login          = "dbadmin"
  administrator_login_password = "Password1234!"

  tags {
    environment = "production"
  }
}

# Create SQL Database
resource "azurerm_sql_database" "bdassqldbprod" {
  name                = "prodsqldb-${format("%02d", count.index+1)}"
  resource_group_name = "${azurerm_resource_group.production.name}"
  location            = "${azurerm_resource_group.production.location}"
  server_name         = "${azurerm_sql_server.mssqlserver.name}"
  edition             = "Standard"

  tags {
    environment = "production"
  }
}
