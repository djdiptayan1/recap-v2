#!/bin/bash

set -e

IMAGE="djdiptayan/hackrecap-backend:latest"
CONTAINER_NAME="recappp"

echo "Pulling latest image..."
docker pull $IMAGE

echo "Stopping existing container (if any)..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

echo "Starting new container..."
docker run -d \
  --name $CONTAINER_NAME \
  --env-file recapEnv.env \
  -e FIREBASE_SERVICE_ACCOUNT="<paste_base64_string_here>" \
  -p 3000:3000 \
  $IMAGE

echo "Container restarted successfully."