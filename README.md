# AKS Automatic with Microsoft Foundry samples

This repository contains deployable examples for running applications on Azure Kubernetes Service (AKS) Automatic with Microsoft Foundry as the model backend. Both samples use Microsoft Entra workload identity, so pods call Foundry without storing model API keys in Kubernetes.

## Samples

| Sample | Experience | Network exposure |
| --- | --- | --- |
| [Microsoft Foundry chatbot](mychatbot-foundry/README.md) | Streamlit chat application backed by a Foundry model deployment | Public Kubernetes `LoadBalancer` service |
| [Microsoft Foundry MCP server](mcp-server-foundry/README.md) | Streamable-HTTP MCP server exposing the `ask_foundry` tool | Private Kubernetes `ClusterIP` service accessed with port forwarding |

Each sample provisions its own AKS cluster, Azure Container Registry, Foundry resource and model deployment, managed identity, federated credential, container image, and Kubernetes workload. Resource names and Azure settings are defined independently in each sample's `set-variables.sh` file.

## Architecture

The samples follow the same deployment flow:

1. Create an AKS Automatic cluster and Azure Container Registry.
2. Create a Microsoft Foundry resource and model deployment.
3. Configure a user-assigned managed identity and Kubernetes workload identity federation.
4. Build the application image with Azure Container Registry Tasks.
5. Deploy the application to AKS and authenticate to Foundry with Microsoft Entra ID.

## Prerequisites

- Azure CLI authenticated to a subscription where you can create AKS, ACR, Cognitive Services, managed identities, federated credentials, and role assignments
- Azure CLI support for `az aks create --sku automatic`
- `kubectl` and `yq`
- Azure AI model access and sufficient quota for the configured region, SKU, and capacity

## Get started

Choose one sample and run its numbered scripts from that sample's directory:

```bash
cd mychatbot-foundry
# or: cd mcp-server-foundry
```

Review `set-variables.sh` before deploying. Azure resource names such as Foundry accounts and container registries must be globally unique. The resources are billable; use the sample's `09-cleanup.sh` script when you no longer need them, and review the script before deleting any shared resource group.

## Repository layout

```text
.
├── mychatbot-foundry/   # Streamlit chatbot sample
├── mcp-server-foundry/  # Model Context Protocol server sample
└── LICENSE
```

## License

This project is licensed under the [MIT License](LICENSE).
