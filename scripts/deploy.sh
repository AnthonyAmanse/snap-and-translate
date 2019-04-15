#!/bin/bash

# devops pipeline specific

# View build properties
if [ -f build.properties ]; then
  echo "build.properties:"
  cat build.properties
else
  echo "build.properties : not found"
fi

# Make sure the cluster is running and get the ip_address
IPS=$(ibmcloud ks workers $PIPELINE_KUBERNETES_CLUSTER_NAME | grep normal | awk '{ print $2 }')
for ip_addr in $IPS; do
  if [ -z $ip_addr ]; then
    echo "$PIPELINE_KUBERNETES_CLUSTER_NAME not created or workers not ready"
    exit 1
  fi
done

# substitute image name
sed -i "s#registry.ng.bluemix.net/<namespace>/watsontesseract:1#${WATSON_TESSERACT_IMAGE}#" server/watson-lang-trans.yml

# handle WATSON_API_KEYS_WERE_PROVIDED with if else statement
# delete lines after volume so that deployment would not look for these bindings
# sed -i '' '/volumes/,$d' server/watson-lang-trans.yml
# else create services

# create services
ibmcloud service create language_translator lite toolchain-created-translator-service
ibmcloud service create natural-language-understanding free toolchain-created-nlu-test
# bind services
ibmcloud ks cluster-service-bind --cluster anthony-dev --namespace default --service toolchain-created-translator-service
ibmcloud ks cluster-service-bind --cluster anthony-dev --namespace default --service toolchain-created-nlu-service
# check secrets
kubectl get secrets

sed -i "s#<binding-ocrlangtranslator>#binding-toolchain-created-translator-service#" server/watson-lang-trans.yml
sed -i "s#<binding-ocrnlu>#toolchain-toolchain-created-nlu-service#" server/watson-lang-trans.yml

# show yaml file
cat server/watson-lang-trans.yml

# apply yaml file
kubectl apply -f server/watson-lang-trans.yml

# get k8s resources
kubectl get nodes -o wide
kubectl get svc
kubectl get pods
