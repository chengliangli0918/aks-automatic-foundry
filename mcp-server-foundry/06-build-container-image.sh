#!/bin/bash

# Variables
source ./set-variables.sh

# Build and push the image in Azure Container Registry without requiring local Docker.
az acr build \
	--registry "$acrName" \
	--image "$imageName:$tag" \
	--file Dockerfile \
	--subscription "$subscriptionId" \
	.
