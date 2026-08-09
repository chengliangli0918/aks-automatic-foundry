import logging
import os

from azure.ai.inference import ChatCompletionsClient
from azure.ai.inference.models import SystemMessage, UserMessage
from azure.identity import DefaultAzureCredential
from mcp.server.fastmcp import FastMCP

# Read environment variables
title = os.environ.get("TITLE", "MCP server backed by AKS and Microsoft Foundry")
system = os.environ.get("SYSTEM", "You are a helpful assistant.")
model_endpoint = os.environ["MODEL_ENDPOINT"]
model_deployment = os.environ["MODEL_DEPLOYMENT"]
temperature = float(os.environ.get("TEMPERATURE", 0.5))
port = int(os.environ.get("PORT", 8080))

credential = DefaultAzureCredential()
model_client = ChatCompletionsClient(
    endpoint=model_endpoint,
    credential=credential,
    credential_scopes=["https://ai.azure.com/.default"],
)

# stateless_http lets replicas serve requests independently, since AKS load balances across pods with no session affinity.
mcp = FastMCP(title, host="0.0.0.0", port=port, stateless_http=True)


@mcp.tool()
def ask_foundry(prompt: str) -> str:
    """Send a prompt to the Microsoft Foundry model deployment and return the model's response."""
    try:
        completion = model_client.complete(
            model=model_deployment,
            messages=[SystemMessage(content=system), UserMessage(content=prompt)],
            temperature=temperature,
        )
        return completion.choices[0].message.content
    except Exception as e:
        logging.exception(f"Exception in ask_foundry: {e}")
        raise


if __name__ == "__main__":
    mcp.run(transport="streamable-http")
