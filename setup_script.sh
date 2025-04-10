#!/usr/bin/env bash

SRC_DIR="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)"
IMAGE=$1
echo "image is: $1" 

tput bold
echo "Create Kind cluster:"
tput sgr0
echo ""
kind create cluster --name inference-router ## --config ...

tput bold
echo "Build vLLM-sim image and load to kind cluster:"
tput sgr0
echo ""
cd $SRC_DIR/../vllm-sim
make build-vllm-sim-image
kind load docker-image vllm-sim/vllm-sim:0.0.2 --name inference-router

# tput bold
# echo "Build epp image and load to kind cluster:"
# tput sgr0
# echo ""
# cd $SRC_DIR/../gateway-api-inference-extension
#KIND_CLUSTER=inference-router make image-kind ## builds the image and loads it to kind cluster inference-router
kind load docker-image ${IMAGE} --name inference-router

tput bold
echo "Install envoy:"
tput sgr0
echo ""
kubectl apply --server-side -f https://github.com/envoyproxy/gateway/releases/download/v1.3.2/install.yaml

tput bold
echo "deploy vllm-sim model servers:"
tput sgr0
echo ""
kubectl apply -f $SRC_DIR/manifests/vllm-sim.yaml

tput bold
echo "deploy Gateway Inference Extension CRDs:"
tput sgr0
echo ""
kubectl apply -f ../gateway-api-inference-extension/config/crd/bases

tput bold
echo "deploy InferenceModel yaml:"
tput sgr0
echo ""
kubectl apply -f $SRC_DIR/manifests/inferencemodel.yaml

tput bold
echo "deploy InferencePool related resources yaml:"
tput sgr0
echo ""
IMAGE=$1 envsubst < $SRC_DIR/manifests/inferencepool-resources.yaml | kubectl apply -f -