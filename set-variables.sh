# Azure Subscription and Tenant
subscriptionId="c582d154-33c4-47e4-a3c2-0632d20b12eb"
az account set --subscription "$subscriptionId"
subscriptionName=$(az account show --subscription "$subscriptionId" --query name --output tsv)
tenantId=$(az account show --subscription "$subscriptionId" --query tenantId --output tsv)

# ACR
acrName="charliliacr"
acrResourceGroupName="aks-foundry"
location="westus"
attachAcr=true
imageName="mychatbot"
tag="v1"
containerName="mychatbot"
image="$acrName.azurecr.io/$imageName:$tag"
imagePullPolicy="IfNotPresent"

# Workload Identity 
managedIdentityName="myIdentity"
federatedIdentityName="myFedIdentity"

# Microsoft Foundry
foundryName="charlili-foundry"
foundryResourceGroupName="aks-foundry"
foundryEndpoint="https://$foundryName.services.ai.azure.com/models"
foundryModel="gpt-5.4-mini"
foundryModelVersion="2026-03-17"
foundryDeployment="gpt-5.4-mini"
foundrySkuName="GlobalStandard"
foundrySkuCapacity=10

# AKS Cluster
aksClusterName="charlili-aks"
aksResourceGroupName="aks-foundry"
aksKubeConfigPath="/tmp/kubeconfig"
aksNodeVmSize="Standard_D2s_v5"
aksNodeCount=4

# Chatbot Application
namespace="default"
serviceAccountName="workload-identity-sa"
deploymentTemplate="deployment.yaml"
serviceTemplate="service.yaml"

# Chatbot argument
title="Chatbot running on Azure Kubernetes Service, powered by Microsoft Foundry"
temperature="0.5"
