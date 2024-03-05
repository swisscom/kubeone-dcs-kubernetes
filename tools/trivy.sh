#!/bin/bash
set -e
set -u
set -o pipefail
if [[ "$(basename ${PWD})" == "tools" ]]; then
	cd ..
fi

# ======================================================================================================================
echo " "
echo "running Trivy scan for Kubernetes ..."

#trivy k8s --report=all --slow --format=json --output=trivy.json --timeout 900s cluster
trivy k8s --report=all --slow --format=table --output=trivy.out --timeout 900s cluster

echo " "
echo "================================================================================================================="
echo "Scan complete, the result is available in [trivy.out]"
echo "================================================================================================================="
# ======================================================================================================================
