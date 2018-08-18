# Azure Support Scripts
Azure PowerShell Scripts ported to BASH. This script solves the very same purpose for people who are BASH lovers and are not comfortable with PowerShell.

This repository contains scripts that are used by Microsoft Customer Service and Support (CSS) to aid in gaining better insight into, or troubleshooting issues with, deployments in Microsoft Azure. A goal of this repository is provide transparency to Azure customers who want to better understand the scripts being used and to make these scripts accessible for self-help scenarios outside of Microsoft support.

These scripts are generally intended address a particular scenario and are not published as samples of best practices for inclusion in applications.

    For code and scripting examples of best practice see OneCode, OneScript, and the Microsoft Azure Script Center.
    For documentation on how to build and deploy applications to Microsoft Azure, please see the Microsoft Azure Documentation Center.
    For more information about support in Microsoft Azure see http://azure.microsoft.com/support

## Overview
If an Azure VM is inaccessible it may be necessary to attach the OS disk to another Azure VM in order to perform recovery steps. The VM recovery scripts automate the recovery steps below.

1. Stops the problem VM.
2. Takes a snapshot of the problem VM's OS disk.
3. Creates a new temporary VM ("rescue VM"). 
4. Attaches the problem VM's OS disk as a data disk on the rescue VM.
5. You can then connect to the rescue VM to investigate and mitigate issues with the problem VM's OS disk.
6. Detaches the problem VM's OS disk from the rescue VM.
7. Performs a disk swap to swap the problem VM's OS disk from the rescue VM back to the problem VM.
8. Removes the resources that were created for the rescue VM.

## Component Specification
##### new-rescue.sh
You may run this script if you may require a temporary (Rescue) VM for troubleshooting of the OS Disk.
This Script Performs the following operation :
1. Stop and Deallocate the Problematic Original VM
2. Make a OS Disk Copy of the Original Problematic VM depending on the type of Disks
3. Create a Rescue VM (based on the Original VM's Distribution and SKU) and attach the OS Disk copy to the Rescue VM
4. Start the Rescue VM for troubleshooting.

##### restore-original.sh
You may run this script once the troubleshooting of the OS Disk is performed on a Rescue VM.
This Script Performs the following operation :
1. Detach the Attached OS Disk to the Rescue VM
2. Stop and Deallocate the Problematic Original VM
3. Perform OS Disk Swap with Detached OS Disk with the Problematic VM
4. Start the Fixed (Problematic) Original VM with the swapped OS Disk

## Supportability
The Support for this script is limited to the Non-Encrypted Virtual Machines available as part of Microsoft Azure Resource Manager.
The script does not store the Encryption Settings of the Virtual Machines and hence absolutely not to be run on an Encrypted Azure Virtual Machine for Troubleshooting.

The Script fails for special custom Virtual Machines Images which follow the following criterion:
1. Only one Virtual Machine may be created in a Single resource group.

## Requirements
The following Requirements are Mandatory inorder to run the scripts successfully
1. Python - (Any verison as long as Azure CLI is supported)
2. BASH command processor or BASH Terminal.
3. An Active Azure Subscription.
4. JQuery commandline Processing | jq command for BASH terminal

    In RHEL/Centos Operating System
      ``` bash
      yum install jq
      ```
    In Ubuntu/Debian Operating System
    ``` bash
    apt install jq
    ```
 
The best way to run the above script is to use the Cloud Shell in Microsoft Azure Portal. Cloud Shell satisfies all the above requirements and is the best option. For more information, please look at the usage page.

## Usage
1. Launch BASH in Azure Cloud Shell 

   <a href="https://shell.azure.com/" target="_blank"><img border="0" alt="Launch Cloud Shell" src="https://shell.azure.com/images/launchcloudshell@2x.png"></a>

2. If it is your first time connecting to Azure Cloud Shell, select **`BASH`** when you see **`Welcome to Azure Cloud Shell`**. 

3. If you then see **`You have no storage mounted`**, select the subscription where the VM you are troubleshooting resides, then select **`Create storage`**.

###### You may skip the above steps if you already possess a BASH terminal which satisfies the Requirement section.

4. The time has now arrived to start executing scripts. First clone the git repository to our cloud shell.
``` bash
git clone https://github.com/sribs/azure-support-scripts
```

5. Change directory to the Repository directory that is now available in the cloud shell after performing Step 4.
``` bash
cd azure-support-scripts
```

6. Execute the commands as per the requirement as stated in the Component Specification section.
``` bash
./restore-original.sh -s <Subscription Id> --rescue-vm-name <Rescue VM Name> --rescue-resource-group <Rescue VM Resource Group> -g <Original VM's resource group> -n <Original VM Name> --os-disk <FIxed OS Disk now used for OS Disk Swap>
```

``` bash
./new-rescue.sh --recue-vm-name <Rescue VM Name> -g <Original VM Resource Group> -n <Original VM Name> -s <Subscription Id> -u <Admin Username for Rescue VM> -p <Admin Password for Rescue VM>
```
