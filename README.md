# Azure Automation Hackathon

Let me invite you for Infra hackathon for Azure automation ( we can take a look at other clouds of course ).
Goal is to come up with solution for automation tool which will be best for us to use in Azure cloud.

# Basic criteria:

1.	Automation possibilities 
2.	Monitoring tools
3.	Easy to learn
4.	Integration with other components : Zabbix, Heat ,SNOW etc.

# Scenario

1.	We will have 3 linux VMs 
- a.	Ubuntu Server No 1
- b.	Ubuntu Server No 2
- c.	Ubuntu Server No 3
- d.	Ubuntu Server No 4 - Airflow machine
- e.	Ubuntu Server No 5 - Cronicle machine

2.	Create automation based on tags or other available to user method to:
3.	Start Ubuntu Server No 1 at desired time,day,weekday,month,year etc. for eg. 7:30 AM CET. 
4.	Start Ubuntu Server No 2 only if Ubuntu Server No 3 is running.
5.	Stop Ubuntu Server No 1 at desired time, day, weekday, month, year etc. for eg. 7:30 PM CET. 
6.	Start Ubuntu Server No 3 only if Ubuntu Server No 2 is stopped.
7.	Monitor execution
8.	Check if manual process is possible in case of emergency
9.	AOB

We'd like to test applications:
-	Azure Automation Account with Runbooks from Gallery
-	Azure Logic App
-	Apache Airflow 
-	Cronicle
-	Any other tool you like to verify




# Installation instruction
Prerequisits:
CLI in Portal.azure.com or if you like to run it from your computer:
- Install Azure CLI - https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
- Install Terraform - https://www.terraform.io/downloads.html
- Install Putty     - https://www.putty.org/  
- Optional VS Code  - https://code.visualstudio.com/ with extensions you like  

Code to create entire environment is available in terraform.
To run code you need to provide environment variables
-	TF_VAR_SUBSCRIPTION_ID  - sandbox subscription id
-	TF_VAR_ADMIN_USERNAME   - admin user name
-	TF_VAR_ADMIN_PASSWORD   - admin password ( can be taken from key vault )
-	TF_VAR_RESOURCE_GROUP   - resource group
-	TF_VAR_PREFIX           - name of prefix for resources like Vms, disks etc


1. To install create a folder which you like to use for Terraform.
2. Run curl https://raw.githubusercontent.com/SzymonJozefowicz/azure-automation-hackathon/master/code/terraform/main.tf -o main.tf and save a code in folder you choose.
3. Login to Azure using az login
4. Run terraform init
5. Run terraform plan
6. Run terraform apply

How to install Airflow  
https://airflow.apache.org/installation.html  
https://vujade.co/install-apache-airflow-ubuntu-18-04/  

How to install Cronicle
https://github.com/jhuckaby/Cronicle

Cronicle needs to be installed as root.

sudo su -  
apt install npm  
curl -s https://raw.githubusercontent.com/jhuckaby/Cronicle/master/bin/install.js | node  
/opt/cronicle/bin/control.sh setup  
/opt/cronicle/bin/control.sh start  
http://YOUR_SERVER_HOSTNAME:3012  


After hackathon we will run terraform destroy to clean up Azure.







