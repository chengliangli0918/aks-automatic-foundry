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
name: Host an MCP server on AKS Automatic with Microsoft Foundry as the backend
description: Provision AKS Automatic and Microsoft Foundry model serving, then expose an MCP tool from AKS without secrets.
---

# MCP server on AKS Automatic, backed by Microsoft Foundry

[Repository overview](../README.md) | [Chatbot sample](../mychatbot-foundry/README.md)

This sample provisions an AKS Automatic cluster, a Microsoft Foundry resource with a chat model deployment, and a [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) server. AKS Automatic provides a managed cluster configuration with node provisioning, scaling, and workload identity enabled by default. The pod exchanges its projected Kubernetes service-account token for a Microsoft Entra token; no model API key is stored in Kubernetes.

The MCP server exposes a single tool, `ask_foundry`, that forwards a prompt to the Microsoft Foundry model deployment and returns the response. It uses the [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk) `FastMCP` server with the streamable-HTTP transport, so any MCP-compatible client or agent framework can call it over the network.

The sample is configured to use subscription `8ecadfc9-d1a3-4ea4-b844-0d9f87e4d7c8` and create resources in `westus3` under `charlili-mcp-rg`. Resource names, location, model, and capacity are defined in `set-variables.sh`. Foundry account and container registry names are globally unique, so change them if the configured names are unavailable.

## Security note

The MCP endpoint has no authentication or authorization of its own, and `ask_foundry` sends whatever prompt it receives to the Foundry model deployment. To keep it out of reach of the public internet, `service.yaml` deploys it as a `ClusterIP` service instead of a `LoadBalancer`. Use `kubectl port-forward` (or an authenticated ingress/API gateway of your own) to reach it. Add authentication and input validation before exposing this pattern beyond a trusted network.

## Prerequisites

- Azure CLI authenticated with permission to create AKS, ACR, Cognitive Services, managed identities, federated credentials, and role assignments
- Azure CLI support for `az aks create --sku automatic`
- `kubectl` and `yq`
- Azure AI model access and quota for the model, region, SKU, and capacity configured in `set-variables.sh`

Local Docker is not required. The `06-build-container-image.sh` script uses an Azure Container Registry cloud build to build and push the image. Docker is needed only for the optional local `debug-mcpserver.sh` workflow.

## Deploy with Microsoft Foundry

From the repository root, enter this sample directory and run the scripts in order:

```bash
cd mcp-server-foundry
./01-create-aks-cluster.sh
./02-create-acr.sh
./03-create-foundry.sh
./04-create-managed-identity.sh
./05-create-service-account.sh
./06-build-container-image.sh
./07-push-image-to-acr.sh
./08-deploy-mcpserver.sh
```

The `01-create-aks-cluster.sh` script creates the cluster with the AKS Automatic SKU and disables SSH access. AKS Automatic selects and manages compute capacity rather than using a fixed node VM size or node count defined in this repository. The `04-create-managed-identity.sh` and `05-create-service-account.sh` scripts connect the Kubernetes service account to a user-assigned managed identity and authorize it to call Foundry.

## Call the MCP server

Forward the service to your workstation, since it's deployed as `ClusterIP`:

```bash
export KUBECONFIG=/tmp/kubeconfig-mcp
kubectl port-forward service/mcpserver 8080:80
```

The MCP endpoint is now reachable at `http://127.0.0.1:8080/mcp` using the streamable-HTTP transport. Point an MCP client (for example, the [MCP Inspector](https://github.com/modelcontextprotocol/inspector) or an agent framework with MCP support) at that URL and call the `ask_foundry` tool with a `prompt` argument.

Use `debug-mcpserver.sh` to run the image locally with credentials from the host's Azure CLI cache before deploying it.

The setup creates an `AIServices` Foundry resource, deploys `gpt-5.4-mini`, and assigns the `Cognitive Services User` role to the workload identity. The MCP server calls the Foundry `/models` endpoint by using `azure-ai-inference`.

## Cleanup

```bash
./09-cleanup.sh
```

The cleanup script deletes the Foundry resource and the resource groups configured in `set-variables.sh`. Review it before running if those groups contain resources not created by this sample.

## License

This project is licensed under the [MIT License](../LICENSE).
