# Create a namespace
kubectl create ns python-test

# Create a registry secret, update the PASSWORD_HERE variable before running
kubectl create secret docker-registry regcred  --docker-username=jkuspa --docker-password=PASSWORD_HERE -n python-test

# Add the secret to the default service account
#kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "regcred"}]}' -n python-test

# Install the ootb supply chain
tanzu package install ootb-supply-chain-basic \
  --package-name ootb-supply-chain-basic.tanzu.vmware.com \
  --version 0.11.0 \
  --namespace tap-install \
  --values-file ootb-supply-chain-basic-values.yaml


# Legacy namespace configuration
# https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/namespace-provisioner-legacy-manual-namespace-setup.html
cat <<EOF | kubectl -n python-test apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: tap-registry
  annotations:
    secretgen.carvel.dev/image-pull-secret: ""
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: e30K
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
secrets:
  - name: regcred
imagePullSecrets:
  - name: regcred
  - name: tap-registry
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default-permit-deliverable
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: deliverable
subjects:
  - kind: ServiceAccount
    name: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default-permit-workload
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: workload
subjects:
  - kind: ServiceAccount
    name: default
EOF