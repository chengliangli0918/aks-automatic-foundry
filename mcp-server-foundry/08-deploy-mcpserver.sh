#!/bin/bash

# Variables
source ./set-variables.sh

echo $image
export KUBECONFIG=$aksKubeConfigPath

# Attach ACR to AKS cluster
if [[ $attachAcr == true ]]; then
  echo "Granting the AKS kubelet identity AcrPull on $acrName..."
  acrId=$(az acr show \
    --name "$acrName" \
    --resource-group "$acrResourceGroupName" \
    --query id \
    --output tsv)
  kubeletObjectId=$(az aks show \
    --name "$aksClusterName" \
    --resource-group "$aksResourceGroupName" \
    --query identityProfile.kubeletidentity.objectId \
    --output tsv)
  acrPullRoleId=$(az role definition list \
    --name AcrPull \
    --subscription "$subscriptionId" \
    --query '[0].id' \
    --output tsv)
  acrAssignmentsUrl="https://management.azure.com$acrId/providers/Microsoft.Authorization/roleAssignments?api-version=2022-04-01"
  acrPullAssigned=$(az rest \
    --method get \
    --url "$acrAssignmentsUrl" \
    --query "length(value[?properties.principalId=='$kubeletObjectId' && properties.roleDefinitionId=='$acrPullRoleId'])" \
    --output tsv)
  if [[ $acrPullAssigned -eq 0 ]]; then
    az role assignment create \
      --assignee-object-id "$kubeletObjectId" \
      --assignee-principal-type ServicePrincipal \
      --role AcrPull \
      --scope "$acrId" \
      --subscription "$subscriptionId" 1>/dev/null
  else
    echo "The AKS kubelet identity already has AcrPull on $acrName"
  fi
fi

# Check if namespace exists in the cluster
result=$(kubectl get namespace -o jsonpath="{.items[?(@.metadata.name=='$namespace')].metadata.name}")

if [[ -n $result ]]; then
  echo "$namespace namespace already exists in the cluster"
else
  echo "$namespace namespace does not exist in the cluster"
  echo "creating $namespace namespace in the cluster..."
  kubectl create namespace $namespace
fi

# Create deployment
cat $deploymentTemplate |
    yq "(.spec.template.spec.containers[0].image)|="\""$image"\" |
    yq "(.spec.template.spec.containers[0].imagePullPolicy)|="\""$imagePullPolicy"\" |
    yq "(.spec.template.spec.serviceAccountName)|="\""$serviceAccountName"\" |
    yq "(.spec.template.spec.containers[0].env[0].value)|="\""$title"\" |
    yq "(.spec.template.spec.containers[0].env[1].value)|="\""$system"\" |
    yq "(.spec.template.spec.containers[0].env[2].value)|="\""$temperature"\" |
    yq "(.spec.template.spec.containers[0].env[3].value)|="\""$foundryEndpoint"\" |
    yq "(.spec.template.spec.containers[0].env[4].value)|="\""$foundryDeployment"\" |
    kubectl apply -n $namespace -f -

# Create service
kubectl apply -f $serviceTemplate -n $namespace
