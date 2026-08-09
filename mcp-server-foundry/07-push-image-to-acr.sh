#!/bin/bash

# Variables
source ./set-variables.sh

# Step 06 uses ACR Tasks to build and push the image. Verify the expected tag exists.
remoteTag=$(az acr repository show-tags \
	--name "$acrName" \
	--repository "${imageName,,}" \
	--subscription "$subscriptionId" \
	--query "[?@=='$tag'] | [0]" \
	--output tsv)

if [[ $remoteTag != "$tag" ]]; then
	echo "Image '$image' was not found in Azure Container Registry"
	exit 1
fi

echo "Image '$image' is available in Azure Container Registry"
