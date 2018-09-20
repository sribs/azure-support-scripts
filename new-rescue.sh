#!/bin/bash

# Module : new-rescue.sh
# Author : Sriharsha B S (sribs@microsoft.com, Azure Linux Escalation Team),  Dinesh Kumar Baskar (dibaskar@microsoft.com, Azure Linux Escalation Team)
# Date : 13th August 2018
# Description : BASH form of New-AzureRMRescueVM powershell command.

help="\n
========================================================================================\n
new-rescue.sh --> BASH form of New-AzureRMRescueVM powershell command.\n
========================================================================================\n\n\n

========================================================================================\n
Disclaimer\n
========================================================================================\n\n
Do not use this script on an Encrypted VM. This script does not store the encrypted settings.
\n\n\n

========================================================================================\n
Description\n
========================================================================================\n\n
You may run this script if you may require a temporary (Rescue VM) for troubleshooting of the OS Disk.\n
This Script Performs the following operation :\n
1. Stop and Deallocate the Problematic Original VM\n
2. Make a OS Disk Copy of the Original Problematic VM depending on the type of Disks\n
3. Create a Rescue VM (based on the Original VM's Distribution and SKU) and attach the OS Disk copy to the Rescue VM\n
4. Start the Rescue VM for troubleshooting.\n\n\n

=========================================================================================\n
Arguments and Usage\n
=========================================================================================\n\n
All the arguments are mandatory. However, arguments may be passed in any order\n
1. --rescue-vm-name : Name of the Rescue VM Name\n
2. -u or --username : Rescue VM's Username\n
3. -g or --resource-group : Problematic Original VM's Resource Group\n
4. -n or --name : Problematic Original VM\n
5. -p or --password : Rescue VM's Password\n
6. -s or --subscription : Subscription Id where the respective resources are present.\n\n

Usage Example: ./new-rescue.sh --recue-vm-name debianRescue -g debian -n debian9 -s  xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -u sribs -p Welcome@1234\n\n\n
"

POSITIONAL=()
echo $#
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
    -u|--username)
    user="$2"
    shift # past argument
    shift # past value
    ;;
    --rescue-vm-name)
    rn="$2"
    shift # past argument
    shift
    ;;
    -p|--password)
    password="$2"
    shift # past argument
    shift
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

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

vm_details=$(az vm show -g $g -n $vm)

echo "Stopping and deallocating the Problematic Original VM"
az vm deallocate -g $g -n $vm
 
os_disk=$(echo $vm_details| jq ".storageProfile.osDisk")
managed=$(echo $os_disk | jq ".[0].managedDisk")
offer=$(echo $vm_details | jq ".storageProfile.imageReference.offer")
publisher=$(echo $vm_details | jq ".storageProfile.imageReference.publisher")
sku=$(echo $vm_details | jq ".storageProfile.imageReference.sku")
version=$(echo $vm_details | jq ".storageProfile.imageReference.version")

urn=$(echo "${publisher//\"}:${offer//\"}:${sku//\"}:${version//\"}")
echo $urn
#echo $managed
disk_uri="null"
resource_group=$g
if [[ $managed = "null" ]]
then
    disk_uri=$(echo $os_disk | jq ".vhd.uri")
    disk_uri=$(echo "${disk_uri//\"}")
    target_disk_name="`echo $disk_uri | awk -F "/" '{print $NF}' | awk -F".vhd" '{print $1}'`-`date +%d-%m-%Y-%T | | sed 's/:/-/g'`"
    #target_disk_name="`echo $disk_uri | awk -F "/" '{print $NF}' | awk -F".vhd" '{print $1}'`-`date +%d-%m-%Y-%T`"
    storage_account=`echo $disk_uri | awk -F "https://" '{print $2}' | awk -F ".blob" '{print $1}'`
    #key=`az storage account keys list -g $resource_group -n $storage_account --output table |  awk '{if($1=="key1")print $3}' | tr -d '[:blank:]'`
    #az storage blob copy start --destination-blob $target_disk_name --destination-container vhds --account-name $storage_account --source-uri $disk_uri
    az storage blob copy start --destination-blob $target_disk_name.vhd --destination-container vhds --account-name $storage_account --source-uri $disk_uri

    az vm create --use-unmanaged-disk --name $rn -g $g --attach-data-disks "https://$storage_account.blob.core.windows.net/vhds/$target_disk_name.vhd" --admin-username $user --admin-password $password --image $urn --storage-sku Standard_LRS 

else
    disk_uri=$(echo $os_disk | jq ".managedDisk.id")
    disk_uri=$(echo "${disk_uri//\"}")
    echo "##### Generatnig Snapshot #######"
    source_disk_name=`echo $disk_uri | awk -F"/" '{print $NF}'`
    snapshot_name="`echo $disk_uri | awk -F"/" '{print $NF}' | sed 's/_/-/g'`-`date +%d-%m-%Y-%T | sed 's/:/-/g'`"
    target_disk_name="`echo $disk_uri | awk -F"/" '{print $NF}'`-copy-`date +%d-%m-%Y-%T | sed 's/:/-/g'`"
    az snapshot create -g $resource_group -n $snapshot_name --source $source_disk_name

    echo "##### Creating Disk from Snapshot #######"

    snapshotId=$(az snapshot show --name $snapshot_name --resource-group $resource_group --query [id] -o tsv)
    az disk create --resource-group $resource_group --name $target_disk_name --sku Standard_LRS --source $snapshotId

    az vm create --name $rn -g $g --attach-data-disks $target_disk_name --admin-username $user --admin-password $password --image $urn --storage-sku Standard_LRS 
fi
 


