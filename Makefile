.DEFAULT_GOAL := help
SHELL := /bin/bash

ROOT_DIR = $(realpath .)
TERRAFORM_DIR = ${ROOT_DIR}/terraform
TERRAFORM_OUTPUT = ${TERRAFORM_DIR}/output.json
SSH_KEY = ${ROOT_DIR}/ssh_key_id_rsa
SSH_PUB_KEY = ${SSH_KEY}.pub
CLUSTER_NAME = kubeone
CONFIG_FILE = kubeone.yaml
CREDENTIALS_FILE = credentials.yaml
KUBECONFIG_FILE = ${CLUSTER_NAME}-kubeconfig

# ======================================================================================================================
.PHONY: help
## help: print this help message
help:
	@echo "Usage:"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'
# ======================================================================================================================

# ======================================================================================================================
.PHONY: all
## all: runs all steps to provision and setup Kubernetes
all: terraform kubeone deployments
# ======================================================================================================================

# ======================================================================================================================
.PHONY: check-env
## check-env: verify current working environment meets all requirements
check-env:
	@which bash 1>/dev/null || (echo 'You have no [bash] ???' && exit 1)
	@which terraform 1>/dev/null || (echo '[terraform] is missing! Get it from https://www.terraform.io/ ...' && exit 1)
	@which kubeone 1>/dev/null || (echo '[kubeone] is missing! Get it from https://github.com/kubermatic/kubeone/ ...' && exit 1)
	@which helm 1>/dev/null || (echo '[helm] is missing! Get it from https://helm.sh/ ...' && exit 1)
	@which jq 1>/dev/null || (echo '[jq] is missing! Get it from https://stedolan.github.io/jq/ ...' && exit 1)
	@which yq 1>/dev/null || (echo '[yq] is missing! Get it from https://github.com/mikefarah/yq/ ...' && exit 1)
	@which curl 1>/dev/null || (echo '[curl] is missing! Get it from https://curl.se/ ...' && exit 1)
	@test -f "${SSH_KEY}" || ssh-keygen -t rsa -b 4096 -f "${SSH_KEY}" -N ''
	@chmod 640 "${SSH_PUB_KEY}" && chmod 600 "${SSH_KEY}"
	@ssh-add "${SSH_KEY}" || true
	@kubeone version > ${ROOT_DIR}/kubeone.version.json

.PHONY: config
## config: (re)generate all configuration files
config: check-env
	@tools/config.sh

.PHONY: install-tools
## install-tools: download and install all required CLI tools into ~/bin
install-tools:
	@tools/install_tools.sh
# ======================================================================================================================

# ======================================================================================================================
.PHONY: terraform
## terraform: provision all infrastructure
terraform: check-env terraform-init terraform-apply terraform-output

.PHONY: terraform-init
## terraform-init: initialize Terraform
terraform-init:
	cd ${TERRAFORM_DIR} && terraform init

.PHONY: terraform-check
## terraform-check: validate Terraform configuration and show plan
terraform-check:
	cd ${TERRAFORM_DIR} && \
		terraform validate && \
		terraform plan

.PHONY: terraform-apply
## terraform-apply: apply Terraform configuration and provision infrastructure
terraform-apply:
	cd ${TERRAFORM_DIR} && \
		terraform apply -auto-approve

.PHONY: terraform-refresh
## terraform-refresh: refresh and view Terraform state
terraform-refresh:
	cd ${TERRAFORM_DIR} && \
		terraform refresh

.PHONY: terraform-output
## terraform-output: output Terraform information into file for KubeOne
terraform-output:
	cd ${TERRAFORM_DIR} && \
		terraform output -json > ${TERRAFORM_OUTPUT}

.PHONY: terraform-destroy
## terraform-destroy: delete and cleanup infrastructure
terraform-destroy:
	cd ${TERRAFORM_DIR} && \
		terraform destroy
# ======================================================================================================================

# ======================================================================================================================
.PHONY: kubeone
## kubeone: run all KubeOne / Kubernetes provisioning steps
kubeone: check-env kubeone-apply kubeone-kubeconfig kubeone-generate-workers kubeone-apply-workers

.PHONY: kubeone-apply
## kubeone-apply: run KubeOne to deploy Kubernetes
kubeone-apply:
	kubeone apply -c ${CREDENTIALS_FILE} -m ${CONFIG_FILE} -t ${TERRAFORM_OUTPUT} --create-machine-deployments=false --auto-approve # --force-upgrade --verbose # --upgrade-machine-deployments

.PHONY: kubeone-kubeconfig
## kubeone-kubeconfig: write kubeconfig file
kubeone-kubeconfig:
	kubeone kubeconfig -c ${CREDENTIALS_FILE} -m ${CONFIG_FILE} -t ${TERRAFORM_OUTPUT} > ${KUBECONFIG_FILE}
	@chmod 600 kubeconfig 2>/dev/null || true
	@chmod 600 ${KUBECONFIG_FILE}

.PHONY: kubeone-generate-workers
## kubeone-generate-workers: generate a machinedeployments manifest for the cluster
kubeone-generate-workers:
	kubeone config machinedeployments -m ${CONFIG_FILE} -t ${TERRAFORM_OUTPUT} > ${ROOT_DIR}/machines/${CLUSTER_NAME}-worker-pool.yml

.PHONY: kubeone-apply-workers
## kubeone-apply-workers: apply machinedeployments to the cluster
kubeone-apply-workers:
	kubectl apply --kubeconfig ${KUBECONFIG_FILE} -f ${ROOT_DIR}/machines

.PHONY: kubeone-addons
## kubeone-addons: list KubeOne addons
kubeone-addons:
	kubeone addons list -c ${CREDENTIALS_FILE} -m ${CONFIG_FILE} -t ${TERRAFORM_OUTPUT}
# ======================================================================================================================

# ======================================================================================================================
.PHONY: deployments
## deployments: install all deployments on Kubernetes
deployments: check-env deploy-longhorn deploy-ingress-nginx deploy-cert-manager deploy-dex deploy-oauth2-proxy deploy-kubernetes-dashboard deploy-hubble deploy-prometheus deploy-loki deploy-promtail deploy-grafana deploy-opencost

.PHONY: deploy-longhorn
## deploy-longhorn: deploy/update Longhorn storage
deploy-longhorn:
	KUBECONFIG=${KUBECONFIG_FILE} deployments/longhorn.sh

.PHONY: deploy-ingress-nginx
## deploy-ingress-nginx: deploy/update Nginx Ingress-controller
deploy-ingress-nginx:
	KUBECONFIG=${KUBECONFIG_FILE} deployments/ingress-nginx.sh

.PHONY: deploy-cert-manager
## deploy-cert-manager: deploy/update Cert-Manager
deploy-cert-manager:
	KUBECONFIG=${KUBECONFIG_FILE} deployments/cert-manager.sh

.PHONY: deploy-dex
## deploy-dex: deploy/update Dex
deploy-dex:
	KUBECONFIG=${KUBECONFIG_FILE} deployments/dex.sh

.PHONY: deploy-oauth2-proxy
## deploy-oauth2-proxy: deploy/update oauth2-proxy
deploy-oauth2-proxy:
	KUBECONFIG=${KUBECONFIG_FILE} deployments/oauth2-proxy.sh

.PHONY: deploy-kubernetes-dashboard
## deploy-kubernetes-dashboard: deploy/update Kubernetes dashboard
deploy-kubernetes-dashboard:
	KUBECONFIG=${KUBECONFIG_FILE} deployments/kubernetes-dashboard.sh

.PHONY: dashboard-token
## dashboard-token: create a temporary login token for Kubernetes dashboard
dashboard-token:
	KUBECONFIG=${KUBECONFIG_FILE} kubectl -n kubernetes-dashboard create token kubernetes-dashboard --duration "60m"

.PHONY: deploy-hubble
## deploy-hubble: deploy/update Hubble UI access
deploy-hubble:
	KUBECONFIG=${KUBECONFIG_FILE} deployments/hubble.sh

.PHONY: deploy-prometheus
## deploy-prometheus: deploy/update Prometheus
deploy-prometheus:
	KUBECONFIG=${KUBECONFIG_FILE} deployments/prometheus.sh

.PHONY: deploy-loki
## deploy-loki: deploy/update Loki
deploy-loki:
	KUBECONFIG=${KUBECONFIG_FILE} deployments/loki.sh

.PHONY: deploy-promtail
## deploy-promtail: deploy/update Promtail
deploy-promtail:
	KUBECONFIG=${KUBECONFIG_FILE} deployments/promtail.sh

.PHONY: deploy-grafana
## deploy-grafana: deploy/update Grafana
deploy-grafana:
	KUBECONFIG=${KUBECONFIG_FILE} deployments/grafana.sh

.PHONY: grafana-password
## grafana-password: get the admin password for Grafana
grafana-password:
	KUBECONFIG=${KUBECONFIG_FILE} kubectl -n grafana get secret grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo

.PHONY: deploy-opencost
## deploy-opencost: deploy/update OpenCost
deploy-opencost:
	KUBECONFIG=${KUBECONFIG_FILE} deployments/opencost.sh

.PHONY: deploy-falco
## deploy-falco: deploy/update Falco Security
deploy-falco:
	KUBECONFIG=${KUBECONFIG_FILE} deployments/falco.sh

.PHONY: deploy-wireguard
## deploy-wireguard: deploy/update WireGuard VPN server
deploy-wireguard:
	KUBECONFIG=${KUBECONFIG_FILE} deployments/wireguard.sh
# ======================================================================================================================

# ======================================================================================================================
.PHONY: oidc-setup
## oidc-setup: setup OIDC for the Kubernetes cluster (install Dex first!)
oidc-setup:
	KUBECONFIG=${KUBECONFIG_FILE} tools/oidc_setup.sh

.PHONY: ssh
## ssh: login to bastion host
ssh: check-env
	@tools/ssh.sh

.PHONY: ssh-control-plane
## ssh-control-plane: login to all control plane nodes (requires TMUX)
ssh-control-plane: check-env
	@tools/ssh_control_plane.sh

.PHONY: trivy-scan
## trivy-scan: run a Kubernetes cluster scan with Trivy
trivy-scan: check-env
	@tools/trivy.sh
# ======================================================================================================================
