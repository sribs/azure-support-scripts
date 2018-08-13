#!/bin/bash

POSITIONAL=()
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
if [[ $(echo "${swap//\"}") -ne "$osdisk" ]]
then
    echo "Problem with Disk Swapping"
    exit;
fi

echo "Successfully swapped the OS disk. Now starting the Problematic VM with OS disk $swap"

# Start the Fixed VM after disk swap
az vm start -g $g -n $vm

echo " Start of the VM $vm Successful"