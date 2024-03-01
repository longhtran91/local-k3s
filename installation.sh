#!/bin/bash

curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="server \
--disable servicelb \
--disable=traefik \
--kube-apiserver-arg=--api-audiences=sts.amazonaws.com \
--kube-apiserver-arg=--service-account-issuer=https://oidc-k3s-local-lhtran.s3.amazonaws.com \
-kube-apiserver-arg=--service-account-jwks-uri=https://oidc-k3s-local-lhtran.s3.amazonaws.com/openid/v1/jwks" \
sh -

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

kubectl apply -f ./setup-yamls/get_jwks.yaml && sleep 30 && ./openid_s3_setup/run.sh oidc-k3s-local-lhtran

helm repo add argo https://argoproj.github.io/argo-helm
helm repo add jetstack https://charts.jetstack.io
helm repo add metallb https://metallb.github.io/metallb
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo update

helm install metallb metallb/metallb --namespace metallb --create-namespace && sleep 30 && kubectl apply -f ./setup-yamls/metallb.yaml

helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace -f ./helm_values/cert-manager-values.yaml
kubectl apply -f ./setup-yamls/iam_pod_identity && sleep 15 && kubectl -n=cert-manager rollout restart deploy/cert-manager
kubectl apply -f ./setup-yamls/clusterissuer.yaml

helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace -f ./helm_values/nginx-ingress-values.yaml
sleep 20
helm install argocd argo/argo-cd --namespace argo --create-namespace -f ./helm_values/argocd-values.yaml
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver --namespace kube-system