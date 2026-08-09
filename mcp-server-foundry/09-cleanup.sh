#!/bin/bash

# Variables
source ./set-variables.sh

echo "Delete and purge Microsoft Foundry '$foundryName' in the '$foundryResourceGroupName' resource group..."

az cognitiveservices account delete -n "$foundryName" -g "$foundryResourceGroupName" --subscription "$subscriptionId"
az cognitiveservices account purge -n "$foundryName" -g "$foundryResourceGroupName" -l "$location" --subscription "$subscriptionId"

echo "Delete resource groups created by this sample..."
declare -A deletedGroups
for resourceGroup in "$foundryResourceGroupName" "$acrResourceGroupName" "$aksResourceGroupName"; do
	if [[ -z ${deletedGroups[$resourceGroup]+x} ]]; then
		az group delete \
			--name "$resourceGroup" \
			--subscription "$subscriptionId" \
			--yes \
			--no-wait
		deletedGroups[$resourceGroup]=1
	fi
done
