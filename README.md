---
page_type: sample
languages:
- azurecli
- bash
- python
- yaml
products:
- azure
- azure-ai-foundry
- azure-kubernetes-service
- azure-container-registry
name: Run a Microsoft Foundry chatbot on AKS with workload identity
description: Provision Microsoft Foundry model serving and call it from AKS without secrets.
---

# Microsoft Foundry chatbot on AKS

This sample provisions an AKS cluster with OIDC and workload identity, a Microsoft Foundry resource with a chat model deployment, and a Streamlit chatbot. The pod exchanges its projected Kubernetes service-account token for a Microsoft Entra token; no model API key is stored in Kubernetes.

The configured subscription is `c582d154-33c4-47e4-a3c2-0632d20b12eb`. Resource names, location, model, and capacity are defined in `set-variables.sh`. Foundry account names are globally unique, so change `foundryName` if the configured name is unavailable.

## Prerequisites

- Azure CLI authenticated with permission to create AKS, ACR, Cognitive Services, managed identities, federated credentials, and role assignments
- `kubectl`, `yq` v4, and Docker
- Azure AI model access and quota for the model, region, SKU, and capacity configured in `set-variables.sh`

## Deploy with Microsoft Foundry

Run the scripts from the repository root in this order:

```bash
./01-create-aks-cluster.sh
./02-create-acr.sh
./03-create-foundry.sh
./04-create-managed-identity.sh
./05-create-service-account.sh
./06-build-container-image.sh
./07-push-image-to-acr.sh
./08-deploy-mychatbot.sh
```

Get the public endpoint after the load balancer is ready:

```bash
export KUBECONFIG=/tmp/kubeconfig
kubectl get service mychatbot --namespace default --watch
```

Open the external IP over HTTP. Use `debug-mychatbot.sh` to run the image locally with credentials from the host's Azure CLI cache.

The setup creates an `AIServices` Foundry resource, deploys `gpt-5.4-mini`, assigns the workload identity the `Cognitive Services User` role, and calls the Foundry `/models` endpoint with `azure-ai-inference`.

## Cleanup

```bash
./09-cleanup.sh
```

The cleanup script deletes the Foundry resource and the resource groups configured in `set-variables.sh`. Review it before running if those groups contain resources not created by this sample.
