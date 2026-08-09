#!/bin/bash

# Variables
source ./set-variables.sh

# Check if ACR resource group exists
az group show --name $acrResourceGroupName &>/dev/null
if [[ $? != 0 ]]; then
   az group create \
    --name $acrResourceGroupName \
    --location $location 1>/dev/null
fi

# Check if Azure Container Registry already exists
echo "Checking if ACR '$acrName' actually exists in the '$acrResourceGroupName' resource group..."

az acr show \
  --name $acrName \
  --resource-group $acrResourceGroupName &>/dev/null

if [[ $? != 0 ]]; then
  echo "No ACR '$acrName' actually exists in the '$acrResourceGroupName' resource group"
  echo "Creating ACR '$acrName' in the '$acrResourceGroupName' resource group..."

  # Create the acr
  az acr create \
    --name $acrName \
    --resource-group $acrResourceGroupName \
    --location $location \
    --subscription $subscriptionId \
    --sku Standard 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "ACR '$acrName' successfully created in the '$acrResourceGroupName' resource group"
  else
    echo "Failed to create ACR '$acrName' in the '$acrResourceGroupName' resource group"
    exit
  fi

else
  echo "ACR '$acrName' already exists in the '$acrResourceGroupName' resource group"
fi
