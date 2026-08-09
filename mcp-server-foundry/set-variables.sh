# Azure Subscription and Tenant
subscriptionId="8ecadfc9-d1a3-4ea4-b844-0d9f87e4d7c8"
az account set --subscription "$subscriptionId"
subscriptionName=$(az account show --subscription "$subscriptionId" --query name --output tsv)
tenantId=$(az account show --subscription "$subscriptionId" --query tenantId --output tsv)

# ACR
acrName="charlilimcpacr"
acrResourceGroupName="charlili-mcp-rg"
location="westus3"
attachAcr=true
imageName="mcpserver"
tag="v1"
containerName="mcpserver"
image="$acrName.azurecr.io/$imageName:$tag"
imagePullPolicy="IfNotPresent"

# Workload Identity
managedIdentityName="mcpIdentity"
federatedIdentityName="mcpFedIdentity"

# Microsoft Foundry
foundryName="charlili-mcp-foundry"
foundryResourceGroupName="charlili-mcp-rg"
foundryEndpoint="https://$foundryName.services.ai.azure.com/models"
foundryModel="gpt-5.4-mini"
foundryModelVersion="2026-03-17"
foundryDeployment="gpt-5.4-mini"
foundrySkuName="GlobalStandard"
foundrySkuCapacity=10

# AKS Cluster
aksClusterName="charlili-mcp-aks"
aksResourceGroupName="charlili-mcp-rg"
aksKubeConfigPath="/tmp/kubeconfig-mcp"

# MCP Server Application
namespace="default"
serviceAccountName="wi-sa"
deploymentTemplate="deployment.yaml"
serviceTemplate="service.yaml"

# MCP Server arguments
title="MCP server running on AKS Automatic, powered by Microsoft Foundry"
system="You are a helpful assistant reachable through the Model Context Protocol."
temperature="0.5"
