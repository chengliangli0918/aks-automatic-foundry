#!/bin/bash

# Variables
source ./set-variables.sh

# Debug the mychatbot on dev machine before on k8s/AKS
docker run -it \
  --rm \
  -p 8080:8080 \
  -e TEMPERATURE=$temperature \
  -e MODEL_ENDPOINT=$foundryEndpoint \
  -e MODEL_DEPLOYMENT=$foundryDeployment \
  -v "$HOME/.azure:/root/.azure:ro" \
  --name $containerName \
  $imageName:$tag
