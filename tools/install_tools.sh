#!/bin/bash
set -e
set -u
set -o pipefail
if [[ "$(basename ${PWD})" == "tools" ]]; then
	cd ..
fi

# ======================================================================================================================
# alternative to sha256sum
if [ -z $(command -v sha256sum) ]; then
	function sha256sum() { openssl sha256 "$@" | awk '{print $2}'; }
fi

function install_tool {
	local -r tool_name="$1"; shift
	local -r tool_url="$1"; shift
	local -r tool_checksum="$1"; shift
	echo " -> checking [${tool_name}] ..."
	CHECKSUM_EXIT=0
	sha256sum "$HOME/bin/${tool_name}" 2>/dev/null | grep "${tool_checksum}" >/dev/null || CHECKSUM_EXIT=$?
	if [ ${CHECKSUM_EXIT} -ne 0 ]; then
		rm -f "$HOME/bin/${tool_name}" >/dev/null || true
		echo " -> downloading [${tool_name}] ..."
		wget -q "${tool_url}" -O "$HOME/bin/${tool_name}" 2>/dev/null
		chmod +x "$HOME/bin/${tool_name}"
	fi
	sha256sum "$HOME/bin/${tool_name}" | grep "${tool_checksum}" >/dev/null || (echo "checksum failed for [${tool_name}]"; exit 1)
}

function install_tool_from_zipfile {
	local -r tool_path="$1"; shift
	local -r tool_name="$1"; shift
	local -r tool_url="$1"; shift
	local -r tool_checksum="$1"; shift
	echo " -> checking [${tool_name}] ..."
	CHECKSUM_EXIT=0
	sha256sum "$HOME/bin/${tool_name}" 2>/dev/null | grep "${tool_checksum}" >/dev/null || CHECKSUM_EXIT=$?
	if [ ${CHECKSUM_EXIT} -ne 0 ]; then
		rm -f "$HOME/bin/${tool_name}" >/dev/null || true
		echo " -> downloading [${tool_name}] ..."
		wget -q "${tool_url}" -O "$HOME/bin/${tool_name}.zip" 2>/dev/null
		echo " -> unpacking [${tool_name}.zip] ..."
		unzip -p "$HOME/bin/${tool_name}.zip" "${tool_path}" > "$HOME/bin/${tool_name}"
		chmod +x "$HOME/bin/${tool_name}"
		rm -f "$HOME/bin/${tool_name}.zip"
	fi
	sha256sum "$HOME/bin/${tool_name}" | grep "${tool_checksum}" >/dev/null || (echo "checksum failed for [${tool_name}]"; exit 1)
}

function install_tool_from_tarball {
	local -r tool_path="$1"; shift
	local -r tool_name="$1"; shift
	local -r tool_url="$1"; shift
	local -r tool_checksum="$1"; shift
	echo " -> checking [${tool_name}] ..."
	CHECKSUM_EXIT=0
	sha256sum "$HOME/bin/${tool_name}" 2>/dev/null | grep "${tool_checksum}" >/dev/null || CHECKSUM_EXIT=$?
	if [ ${CHECKSUM_EXIT} -ne 0 ]; then
		rm -f "$HOME/bin/${tool_name}" >/dev/null || true
		echo " -> downloading [${tool_name}] ..."
		wget -q "${tool_url}" -O "$HOME/bin/${tool_name}.tgz" 2>/dev/null
		echo " -> unpacking [${tool_name}.tgz] ..."
		STRIP_COMPONENTS=$(echo "${tool_path}" | awk -F"/" '{print NF-1}')
		tar -xvzf "$HOME/bin/${tool_name}.tgz" --strip-components=${STRIP_COMPONENTS} -C "$HOME/bin/" "${tool_path}" >/dev/null
		chmod +x "$HOME/bin/${tool_name}"
		rm -f "$HOME/bin/${tool_name}.tgz"
	fi
	sha256sum "$HOME/bin/${tool_name}" | grep "${tool_checksum}" >/dev/null || (echo "checksum failed for [${tool_name}]"; exit 1)
}
# ======================================================================================================================

# ======================================================================================================================
echo " "
echo "Installing CLI tools into [~/bin]:"

if [ ! -d "$HOME/bin" ]; then
	mkdir "$HOME/bin"
fi
export PATH="$HOME/bin:$PATH"

OS=$(uname)
if [ ${OS} == "Darwin" ]; then
	ARCH=$(uname -p)
	if [ ${ARCH} == "arm" ]; then
		echo "-> downloading binaries for Apple Silicon MacOSX ..."
		install_tool "kubectl" "https://storage.googleapis.com/kubernetes-release/release/v1.25.8/bin/darwin/arm64/kubectl" "6519e273017590bd8b193d650af7a6765708f1fed35dcbcaffafe5f33872dfb4"
		install_tool "jq" "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64" "5c0a0a3ea600f302ee458b30317425dd9632d1ad8882259fcaf4e9b868b2b1ef"
		install_tool "yq" "https://github.com/mikefarah/yq/releases/download/v4.34.2/yq_darwin_arm64" "929e0a774d4fbe1fd05fa4284524f2455e4ec1b8b01360099b36c4b3f2a18c57"
		install_tool_from_zipfile "kubelogin" "kubectl-oidc_login" "https://github.com/int128/kubelogin/releases/download/v1.28.0/kubelogin_darwin_arm64.zip" "98b5638f860e8ac026f411a1831773c7e1741d3e37f7cfbb6d63d91dc89796b1"
		install_tool_from_zipfile "kubeone" "kubeone" "https://github.com/kubermatic/kubeone/releases/download/v1.7.2/kubeone_1.7.2_darwin_arm64.zip" "31bce22e6d6ef999538bc13400da3392ac91b21fbbdd02317d0b06dee66a6e95"
		install_tool_from_zipfile "terraform" "terraform" "https://releases.hashicorp.com/terraform/1.2.9/terraform_1.2.9_darwin_arm64.zip" "98f73281fd89a4bac7426149b9f2de8df492eb660b9441f445894dd112fd2c5c"
		install_tool_from_tarball "darwin-arm64/helm" "helm" "https://get.helm.sh/helm-v3.10.3-darwin-arm64.tar.gz" "b5176d9b89ff43ac476983f58020ee2407ed0cbb5b785f928a57ff01d2c63754"
		install_tool_from_tarball "trivy" "trivy" "https://github.com/aquasecurity/trivy/releases/download/v0.44.0/trivy_0.44.0_macOS-ARM64.tar.gz" "452af0f9d12daa82c3621008d1bd489e4f1bfdde277a534b507e9888c67df4c6"
	else
		echo "-> downloading binaries for Intel MacOSX ..."
		install_tool "kubectl" "https://storage.googleapis.com/kubernetes-release/release/v1.25.8/bin/darwin/amd64/kubectl" "4fc94a62065d25f8048272da096e1c5e3bd22676752fb3a24537e4ad62a33382"
		install_tool "jq" "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64" "5c0a0a3ea600f302ee458b30317425dd9632d1ad8882259fcaf4e9b868b2b1ef"
		install_tool "yq" "https://github.com/mikefarah/yq/releases/download/v4.34.2/yq_darwin_amd64" "73b0d5a2a43fdcdca51413ae47cbcacdd6dbfd92a46116ee963f362c798e9cb8"
		install_tool_from_zipfile "kubelogin" "kubectl-oidc_login" "https://github.com/int128/kubelogin/releases/download/v1.28.0/kubelogin_darwin_amd64.zip" "3b12377314085fb1a035150352e27a4979115ac61357d2d851984b749f06cd4e"
		install_tool_from_zipfile "kubeone" "kubeone" "https://github.com/kubermatic/kubeone/releases/download/v1.7.2/kubeone_1.7.2_darwin_amd64.zip" "619bd0c23ac07189766eb66af40e9a9daf4257b7c321a6a85c37cbd139f2da39"
		install_tool_from_zipfile "terraform" "terraform" "https://releases.hashicorp.com/terraform/1.2.9/terraform_1.2.9_darwin_amd64.zip" "4b7b4179653c5d501818d8523575e86e60f901506b986d035f2aa6870a810f24"
		install_tool_from_tarball "darwin-amd64/helm" "helm" "https://get.helm.sh/helm-v3.10.3-darwin-amd64.tar.gz" "8f422d213a9f3530fe516c8b69be74059d89b9954b1afadb9ae6dc81edb52615"
		install_tool_from_tarball "trivy" "trivy" "https://github.com/aquasecurity/trivy/releases/download/v0.44.0/trivy_0.44.0_macOS-64bit.tar.gz" "f1f76bc145e7079410570172a43c1b35bea77a5d8e2ffd15991020ac26dfc4d0"
	fi
else
	echo "-> downloading binaries for Linux ..."
	install_tool "kubectl" "https://storage.googleapis.com/kubernetes-release/release/v1.26.6/bin/linux/amd64/kubectl" "ee23a539b5600bba9d6a404c6d4ea02af3abee92ad572f1b003d6f5a30c6f8ab"
	install_tool "jq" "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" "af986793a515d500ab2d35f8d2aecd656e764504b789b66d7e1a0b727a124c44"
	install_tool "yq" "https://github.com/mikefarah/yq/releases/download/v4.34.2/yq_linux_amd64" "1952f93323e871700325a70610d2b33bafae5fe68e6eb4aec0621214f39a4c1e"
	install_tool_from_zipfile "kubelogin" "kubectl-oidc_login" "https://github.com/int128/kubelogin/releases/download/v1.28.0/kubelogin_linux_amd64.zip" "27f50c9dbebb060afa8ce9c2d30c5b56de319c803749716c273536c688eaed91"
	install_tool_from_zipfile "kubeone" "kubeone" "https://github.com/kubermatic/kubeone/releases/download/v1.7.2/kubeone_1.7.2_linux_amd64.zip" "9658874d7ad52a14b9c2231eb842bdbdfeae5946e41593d1a61b6c52980e9435"
	install_tool_from_zipfile "terraform" "terraform" "https://releases.hashicorp.com/terraform/1.2.9/terraform_1.2.9_linux_amd64.zip" "70fa1a9c71347e7b220165b9c06df0a55f5af57dad8135f14808b343d1b5924a"
	install_tool_from_tarball "linux-amd64/helm" "helm" "https://get.helm.sh/helm-v3.10.3-linux-amd64.tar.gz" "cc5223b23fd2ccdf4c80eda0acac7a6a5c8cdb81c5b538240e85fe97aa5bc3fb"
	install_tool_from_tarball "trivy" "trivy" "https://github.com/aquasecurity/trivy/releases/download/v0.44.0/trivy_0.44.0_Linux-64bit.tar.gz" "5b767ba1b0c398354294aabc43280a206dd5bc6e4b075e0d046f23d0e1003764"
fi
# ======================================================================================================================
echo " "
