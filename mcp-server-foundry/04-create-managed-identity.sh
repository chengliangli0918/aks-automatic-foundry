#!/bin/bash

# Variables
source ./set-variables.sh

az account set --subscription "$subscriptionId"

# Check if the user-assigned managed identity already exists
echo "Checking if '$managedIdentityName' user-assigned managed identity actually exists in the '$aksResourceGroupName' resource group..."

az identity show \
  --name $managedIdentityName \
  --resource-group $aksResourceGroupName &>/dev/null

if [[ $? != 0 ]]; then
  echo "No '$managedIdentityName' user-assigned managed identity actually exists in the '$aksResourceGroupName' resource group"
  echo "Creating '$managedIdentityName' user-assigned managed identity in the '$aksResourceGroupName' resource group..."

  # Create the user-assigned managed identity
  az identity create \
    --name $managedIdentityName \
    --resource-group $aksResourceGroupName \
    --location $location \
    --subscription $subscriptionId 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "'$managedIdentityName' user-assigned managed identity successfully created in the '$aksResourceGroupName' resource group"
  else
    echo "Failed to create '$managedIdentityName' user-assigned managed identity in the '$aksResourceGroupName' resource group"
    exit
  fi
else
  echo "'$managedIdentityName' user-assigned managed identity already exists in the '$aksResourceGroupName' resource group"
fi

# Retrieve the clientId of the user-assigned managed identity
echo "Retrieving clientId for '$managedIdentityName' managed identity..."
clientId=$(az identity show \
  --name $managedIdentityName \
  --resource-group $aksResourceGroupName \
  --query clientId \
  --output tsv)

if [[ -n $clientId ]]; then
  echo "['clientId' clientId  for the '$managedIdentityName' managed identity successfully retrieved"
else
  echo "Failed to retrieve clientId for the '$managedIdentityName' managed identity"
  exit
fi

# Retrieve the principalId of the user-assigned managed identity
echo "Retrieving principalId for '$managedIdentityName' managed identity..."
principalId=$(az identity show \
  --name $managedIdentityName \
  --resource-group $aksResourceGroupName \
  --query principalId \
  --output tsv)

if [[ -n $principalId ]]; then
  echo "'$principalId' principalId  for the '$managedIdentityName' managed identity successfully retrieved"
else
  echo "Failed to retrieve principalId for the '$managedIdentityName' managed identity"
  exit
fi

modelResourceId=$(az cognitiveservices account show \
  --name "$foundryName" \
  --resource-group "$foundryResourceGroupName" \
  --subscription "$subscriptionId" \
  --query id \
  --output tsv)

if [[ -n $modelResourceId ]]; then
  echo "Resource id for '$foundryName' successfully retrieved"
else
  echo "Failed to retrieve the resource id of '$foundryName'"
  exit -1
fi

# Assign the Foundry data-plane role to the managed identity
role="Cognitive Services User"
echo "Checking if '$managedIdentityName' has the '$role' role on '$foundryName'..."
roleDefinitionId=$(az role definition list \
  --name "$role" \
  --subscription "$subscriptionId" \
  --query '[0].id' \
  --output tsv)
roleAssignmentsUrl="https://management.azure.com$modelResourceId/providers/Microsoft.Authorization/roleAssignments?api-version=2022-04-01"
current=$(az rest \
  --method get \
  --url "$roleAssignmentsUrl" \
  --query "length(value[?properties.principalId=='$principalId' && properties.roleDefinitionId=='$roleDefinitionId'])" \
  --output tsv)

if [[ $current -gt 0 ]]; then
  echo "'$managedIdentityName' already has the '$role' role on '$foundryName'"
else
  echo "'$managedIdentityName' does not have the '$role' role on '$foundryName'"

  roleAssigned=false
  for i in {1..30}  #take some time to assign role for newly created managed identity to azure resources
  do   
    echo "Assigning '$role' on '$foundryName', attempt $i..."
    az role assignment create \
      --assignee-object-id "$principalId" \
      --assignee-principal-type ServicePrincipal \
      --role "$role" \
      --scope "$modelResourceId" \
      --subscription "$subscriptionId" 1>/dev/null

    if [[ $? == 0 ]]; then
      echo "'$managedIdentityName' successfully assigned the '$role' role on '$foundryName'"
      roleAssigned=true
      break
    else
      echo "Role assignment failed; retrying"
      sleep 2
    fi
  done

  if [[ $roleAssigned != true ]]; then
    echo "Role assignment failed. Run this command from your Windows machine:"
    echo "az role assignment create --assignee-object-id \"$principalId\" --assignee-principal-type ServicePrincipal --role \"$role\" --scope \"$modelResourceId\" --subscription \"$subscriptionId\""
    exit 1
  fi
fi
