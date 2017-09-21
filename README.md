# Terraform Sample Plans
The following steps and sample plans on Microsoft Azure will provide a simple 'getting started' approach to [Terraform](//www.terraform.io).

  ![Diagram](../images/Azure-Terraform-Example.png)

### Prerequisites
1. [Download Terraform.](https://www.terraform.io/downloads.html)

2. [Create a Service Principal in the Azure Portal.](https://www.terraform.io/docs/providers/azurerm/authenticating_via_service_principal.html#creating-a-service-principal-in-the-azure-portal) Make sure to document the subscription_id, client_id, client_secret and tenant_id for use in later steps.

3. A text editor, [Atom](https://atom.io/) is recommended.

4. [GitHub Desktop.](https://desktop.github.com/)

### Clone Repo
1. [Clone this repo to your local computer.](https://help.github.com/articles/cloning-a-repository/)

2. Open this local directory using the Atom editor (**File, Add Project Folder**).

### Configure Microsoft Azure Provider
1. Select the **SamplePlan.tf** file in Atom and scroll to the **Azurerm** provider.

    ```
    provider "azurerm" {
      subscription_id = ""
      client_id       = ""
      client_secret   = ""
      tenant_id       = ""
    }
    ```

2. Input the subscription_id, client_id, client_secret and tenant_id previously documented into the plan and **save** it.

### Execute Sample Azure Terraform Plan
1. Run ```Terraform init <directory that holds the SamplePlan.tf file>```. [Details on the init command are found in documentation.](https://www.terraform.io/docs/commands/init.html)

    ```
    terraform init C:\Users\Chris\Documents\GitHub\terraform\AzurePlan

    Initializing provider plugins...

    The following providers do not have any version constraints in configuration,
    so the latest version was installed.

    To prevent automatic upgrades to new major versions that may contain breaking
    changes, it is recommended to add version = "..." constraints to the
    corresponding provider blocks in configuration, with the constraint strings
    suggested below.

    * provider.azurerm: version = "~> 0.1"
    * provider.random: version = "~> 0.1"

    Terraform has been successfully initialized!

    You may now begin working with Terraform. Try running "terraform plan" to see
    any changes that are required for your infrastructure. All Terraform commands
    should now work.

    If you ever set or change modules or backend configuration for Terraform,
    rerun this command to reinitialize your working directory. If you forget, other
    commands will detect it and remind you to do so if necessary.
    ```

2. Run ```Terraform plan <directory that holds the SamplePlan.tf file>```. You will be prompted to input an Azure **region** and quantity of **web virtual machines**. [Details on the plan command are found in documentation.](https://www.terraform.io/docs/commands/plan.html)

    ```
    terraform plan C:\Users\Chris\Documents\GitHub\terraform\AzurePlan

    var.region
      Enter a value: eastus

    var.web_vm_count
      Enter a value: 3

    Refreshing Terraform state in-memory prior to plan...
    The refreshed state will be used to calculate this plan, but will not be
    persisted to local or remote state storage.

    The Terraform execution plan has been generated and is shown below.
    Resources are shown in alphabetical order for quick scanning. Green resources
    will be created (or destroyed and then created if an existing resource
    exists), yellow resources are being changed in-place, and red resources
    will be destroyed. Cyan entries are data sources to be read.

    Note: You didn't specify an "-out" parameter to save this plan, so when
    "apply" is called, Terraform can't guarantee this is what will execute.

    + azurerm_lb.weblb
        frontend_ip_configuration.#:                       "1"
        frontend_ip_configuration.0.inbound_nat_rules.#:   "<computed>"
        frontend_ip_configuration.0.load_balancer_rules.#: "<computed>"
        frontend_ip_configuration.0.name:                  "prodwebnlbfe"
        frontend_ip_configuration.0.private_ip_address:    "<computed>"
        frontend_ip_configuration.0.public_ip_address_id:  "${azurerm_public_ip.nlbpip.id}"
        frontend_ip_configuration.0.subnet_id:             "<computed>"
        location:                                          "eastus"
        name:                                              "prodwebnlb"
        private_ip_address:                                "<computed>"
        resource_group_name:                               "${azurerm_resource_group.production.name}"
        tags.%:                                            "<computed>"

    ..................abridged text.............

    Plan: 24 to add, 0 to change, 0 to destroy.
    ````

3. Run ```Terraform apply <directory that holds the SamplePlan.tf file>```. You will be prompted to input an Azure **region** and quantity of **web virtual machines** to deploy. [Details on the apply command are found in documentation.](https://www.terraform.io/docs/commands/apply.html)

    ```
    terraform apply C:\Users\Chris\Documents\GitHub\terraform\AzurePlan

    var.region
      Enter a value: eastus

    var.web_vm_count
      Enter a value: 3

    random_id.random_name: Refreshing state... (ID: YyYuGA)
    azurerm_resource_group.production: Creating...
      location: "" => "eastus"
      name:     "" => "prodbdas63262e18"
      tags.%:   "" => "<computed>"
    azurerm_resource_group.production: Creation complete (ID: /subscriptions/e3e8f458-ebd4-4db5-b25f-...ac3399/resourceGroups/prodbdas63262e18)
    azurerm_sql_server.mssqlserver: Creating...
      administrator_login:          "" => "dbadmin"
      administrator_login_password: "<sensitive>" => "<sensitive>"
      fully_qualified_domain_name:  "" => "<computed>"
      location:                     "" => "eastus"
      name:                         "" => "prodbdas63262e18"
      resource_group_name:          "" => "prodbdas63262e18"
      tags.%:                       "" => "1"
      tags.environment:             "" => "production"
      version:                      "" => "12.0"
    azurerm_network_security_group.prodwebnsg: Creating...
      location:                                           "" => "eastus"
      name:                                               "" => "prodwebnsg"
      resource_group_name:                                "" => "prodbdas63262e18"
      security_rule.#:                                    "" => "1"
      security_rule.624941295.access:                     "" => "Allow"
      security_rule.624941295.description:                "" => ""
      security_rule.624941295.destination_address_prefix: "" => "10.0.1.0/24"
      security_rule.624941295.destination_port_range:     "" => "22"
      security_rule.624941295.direction:                  "" => "Inbound"
      security_rule.624941295.name:                       "" => "allowbastionssh"
      security_rule.624941295.priority:                   "" => "100"
      security_rule.624941295.protocol:                   "" => "tcp"
      security_rule.624941295.source_address_prefix:      "" => "10.0.2.0/24"
      security_rule.624941295.source_port_range:          "" => "*"
      tags.%:                                             "" => "1"
      tags.environment:                                   "" => "Production"

    ..................abridged text.............

    Apply complete! Resources: 24 added, 0 changed, 0 destroyed.
    ```

4. Login to the Azure Portal and validate the services are present as desired.

### Destroy services
1. Run ```Terraform destroy <directory that holds the SamplePlan.tf file>```. You will be prompted to input same Azure **region** and quantity of **web virtual machines** previously used. [Details on the destroy command are found in documentation.](https://www.terraform.io/docs/commands/destroy.html) You will be prompted after the state is refreshed to type in **yes** to confirm destruction of services.

    ```
    var.region
      Enter a value: eastus

    var.web_vm_count
      Enter a value: 3

    random_id.random_name: Refreshing state... (ID: YyYuGA)
    azurerm_resource_group.production: Refreshing state... (ID: /subscriptions/
    azurerm_sql_server.mssqlserver: Refreshing state... (ID: /subscriptions/e3e
    azurerm_network_security_group.mgmtnsg: Refreshing state... (ID: /subscript
    azurerm_public_ip.nlbpip: Refreshing state... (ID: /subscriptions/e3e8f458-
    azurerm_virtual_network.prodvnet: Refreshing state... (ID: /subscriptions/e
    azurerm_availability_set.prodwebservers: Refreshing state... (ID: /subscrip
    azurerm_network_security_group.prodwebnsg: Refreshing state... (ID: /subscr
    azurerm_public_ip.bastionpublicip: Refreshing state... (ID: /subscriptions/
    azurerm_sql_database.bdassqldbprod: Refreshing state... (ID: /subscriptions
    azurerm_lb.weblb: Refreshing state... (ID: /subscriptions/e3e8f458-ebd4-4db
    azurerm_lb_backend_address_pool.backend_pool: Refreshing state... (ID: /sub
    azurerm_lb_probe.prodweblbprobe: Refreshing state... (ID: /subscriptions/e3
    azurerm_lb_rule.prodweblbrule: Refreshing state... (ID: /subscriptions/e3e8
    azurerm_subnet.mgmt: Refreshing state... (ID: /subscriptions/e3e8f458-ebd4-
    azurerm_subnet.dmz: Refreshing state... (ID: /subscriptions/e3e8f458-ebd4-4
    azurerm_network_interface.bastionnic: Refreshing state... (ID: /subscriptio
    azurerm_network_interface.prodwebnic.1: Refreshing state... (ID: /subscript
    azurerm_network_interface.prodwebnic.2: Refreshing state... (ID: /subscript
    azurerm_network_interface.prodwebnic.0: Refreshing state... (ID: /subscript
    azurerm_virtual_machine.bastionvm: Refreshing state... (ID: /subscriptions/
    azurerm_virtual_machine.webprodvm.1: Refreshing state... (ID: /subscription
    azurerm_virtual_machine.webprodvm.2: Refreshing state... (ID: /subscription
    azurerm_virtual_machine.webprodvm.0: Refreshing state... (ID: /subscription

    The Terraform destroy plan has been generated and is shown below.
    Resources are shown in alphabetical order for quick scanning.
    Resources shown in red will be destroyed.

    - azurerm_lb_backend_address_pool.backend_pool

    - azurerm_network_interface.bastionnic

    - azurerm_network_security_group.mgmtnsg

    - azurerm_public_ip.nlbpip

    - azurerm_sql_server.mssqlserver

    - azurerm_lb.weblb

    - azurerm_lb_probe.prodweblbprobe

    - azurerm_lb_rule.prodweblbrule

    - azurerm_network_security_group.prodwebnsg

    - random_id.random_name

    - azurerm_network_interface.prodwebnic[0]

    - azurerm_public_ip.bastionpublicip

    - azurerm_resource_group.production

    - azurerm_sql_database.bdassqldbprod

    - azurerm_subnet.dmz

    - azurerm_subnet.mgmt

    - azurerm_virtual_machine.bastionvm

    - azurerm_virtual_network.prodvnet

    - azurerm_availability_set.prodwebservers

    - azurerm_virtual_machine.webprodvm[0]

    - azurerm_network_interface.prodwebnic[1]

    - azurerm_virtual_machine.webprodvm[1]

    - azurerm_network_interface.prodwebnic[2]

    - azurerm_virtual_machine.webprodvm[2]

    Do you really want to destroy?
    Terraform will delete all your managed infrastructure, as shown above.
    There is no undo. Only 'yes' will be accepted to confirm.

    Enter a value: yes

    ..................abridged text.............

    Destroy complete! Resources: 24 destroyed.
    ```

### Tips
* If you get any errors, particularly on the **destroy** command just run the command again. This happens from time to time when removing a service takes extended periods of time.
