#!/bin/bash

# Module : restore-original.sh
# Author : Sriharsha B S, sribs@microsoft.com
# Date : 13th August 2018
# Description : BASH form of Restore-AzureRmOriginalVM powershell command.

help="\n
========================================================================================\n
restore-original.sh --> BASH form of Restore-AzureRmOriginalVM powershell command\n
========================================================================================\n\n\n

========================================================================================\n
Disclaimer\n
========================================================================================\n\n
Do not use this script on an Encrypted VM. This script does not store the encrypted settings.
Running this on an encrypted VM may render your VM potentially useless\n\n\n

========================================================================================\n
Description\n
========================================================================================\n\n
You may run this script once the troubleshooting of the OS Disk is performed on a Rescue VM.\n
This Script Performs the following operation :\n
1. Detach the Attached OS Disk to the Rescue VM\n
2. Stop and Deallocate the Problematic Original VM\n
3. Perform OS Disk Swap with Detached OS Disk with the Problematic VM\n
4. Start the Fixed (Problematic) Original VM with the swapped OS Disk\n\n\n

=========================================================================================\n
Arguments and Usage\n
=========================================================================================\n\n
All the arguments are mandatory. However, arguments may be passed in any order\n
1. --rescue-vm-name : Name of the Rescue VM Name\n
2. --rescue-resource-group : Rescue VM's resource group\n
3. -g or --resource-group : Problematic Original VM's Resource Group\n
4. -n or --name : Problematic Original VM\n
5. --os-disk : Name of the fixed OS Disk which is currently attached to the Rescue VM and is to be swapped with the Original VM.\n
6. -s or --subscription : Subscription Id where the respective resources are present.\n\n

Usage Example: ./restore-original.sh -s xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx --rescue-vm-name Ubuntu16042 --rescue-resource-group Redhat -g debian -n debian9 --os-disk myvm-os-disk \n\n\n
"

POSITIONAL=()
#echo $# for debugging purpose only
if [[ $# -ne 12 ]]
then
    echo -e $help
    exit;
fi
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -g|--resource-group)
    g="$2"
    shift # past argument
    shift # past value
    ;;
    -n|--name)
    vm="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--subscription)
    subscription="$2"
    shift # past argument
    shift # past value
    ;;
    --rescue-resource-group)
    rg="$2"
    shift # past argument
    shift # past value
    ;;
    --rescue-vm-name)
    rn="$2"
    shift # past argument
    shift
    ;;
    --os-disk)
    osdisk="$2"
    shift # past argument
    shift
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

echo $rg
echo $rn
echo $subscription
echo $g
echo $vm

# Check whether user has an azure account
acc=$(az account show)
echo $acc
if [[ -z $acc ]]
then
    echo "Please login using az login command"
    exit;
fi

# Check if user has a valid azure subscription. If yes, select the subscription as the default subscription
subvalid=$(az account list | jq ".[].id" | grep -i $subscription)
if [[ $(echo "${subvalid//\"}") != "$subscription" || -z $subvalid ]]
then
    echo "No Subscription $subscription exists"
    exit;
fi
az account set --subscription $subscription

# get the OS disk uri for the problematic os disk from the Rescue VM which is currently attached
datadisks=$(az vm show -g $rg -n $rn | jq ".storageProfile.dataDisks")
managed=$(echo $datadisks | jq ".[0].managedDisk")
#echo $managed
disk_uri="null"
if [[ $managed = "null" ]]
then
    disk_uri=$(echo $datadisks | jq ".[].vhd.uri" | grep -i $osdisk)

else
    disk_uri=$(echo $datadisks | jq ".[].managedDisk.id" | grep -i $osdisk)
fi

if [[ -z disk_uri ]]
then
    echo "The rescue VM does not contain the Problematic OS disk"
    exit;
fi

# Detach the Problematic OS disk from the Rescue VM
echo "Detaching the OS disk from the rescue VM"
az vm disk detach -g $rg --vm-name $rn -n $osdisk

# OS Disk Swap Procedure.
echo "Preparing for OS disk swap"
# Stop the Problematic VM
echo "Stopping and deallocating the Problematic Original VM"
az vm deallocate -g $g -n $vm

# Perform the disk swap and verify
echo "Performing the OS disk Swap"
swap=$(az vm update -g $g -n $vm --os-disk $(echo "${disk_uri//\"}") | jq ".storageProfile.osDisk.name")
if [[ $(echo "${swap//\"}") != "$osdisk" ]]
then
    echo "Problem with Disk Swapping"
    exit;
fi

echo "Successfully swapped the OS disk. Now starting the Problematic VM with OS disk $swap"

# Start the Fixed VM after disk swap
az vm start -g $g -n $vm

echo "Start of the VM $vm Successful"
