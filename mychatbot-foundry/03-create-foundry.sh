#!/bin/bash

set -euo pipefail

source ./set-variables.sh

az account set --subscription "$subscriptionId"

if [[ $(az provider show --namespace Microsoft.CognitiveServices --query registrationState --output tsv) != "Registered" ]]; then
  echo "Registering Microsoft.CognitiveServices resource provider..."
  az provider register \
    --namespace Microsoft.CognitiveServices \
    --subscription "$subscriptionId" \
    --wait
fi

if ! az group show --name "$foundryResourceGroupName" &>/dev/null; then
  az group create \
    --name "$foundryResourceGroupName" \
    --location "$location" \
    --subscription "$subscriptionId" 1>/dev/null
fi

echo "Checking for Microsoft Foundry resource '$foundryName'..."
if ! az cognitiveservices account show \
  --name "$foundryName" \
  --resource-group "$foundryResourceGroupName" \
  --subscription "$subscriptionId" &>/dev/null; then
  echo "Creating Microsoft Foundry resource '$foundryName'..."
  foundryResourceUrl="https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$foundryResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$foundryName?api-version=2026-05-01"
  az rest \
    --method put \
    --url "$foundryResourceUrl" \
    --body "{\"location\":\"$location\",\"kind\":\"AIServices\",\"sku\":{\"name\":\"S0\"},\"properties\":{\"customSubDomainName\":\"$foundryName\",\"disableLocalAuth\":true,\"publicNetworkAccess\":\"Enabled\"}}" \
    1>/dev/null
else
  echo "Microsoft Foundry resource '$foundryName' already exists"
fi

echo "Checking for model deployment '$foundryDeployment'..."
if ! az cognitiveservices account deployment show \
  --name "$foundryName" \
  --resource-group "$foundryResourceGroupName" \
  --deployment-name "$foundryDeployment" \
  --subscription "$subscriptionId" &>/dev/null; then
  echo "Deploying '$foundryModel' version '$foundryModelVersion'..."
  az cognitiveservices account deployment create \
    --name "$foundryName" \
    --resource-group "$foundryResourceGroupName" \
    --deployment-name "$foundryDeployment" \
    --model-name "$foundryModel" \
    --model-version "$foundryModelVersion" \
    --model-format OpenAI \
    --sku-name "$foundrySkuName" \
    --sku-capacity "$foundrySkuCapacity" \
    --subscription "$subscriptionId" 1>/dev/null
else
  echo "Model deployment '$foundryDeployment' already exists"
fi

echo "Microsoft Foundry endpoint: $foundryEndpoint"