#!/usr/bin/env bash

export VM_NAME=$1
export APP_NAME=$2

curl http://downloads.openshift-console:80/amd64/linux/oc.tar -o oc.tar

tar xvf oc.tar

./oc get vm ${VM_NAME}

if [[ $? -eq 1 ]]; then

  sed "s/\${VM_NAME}/${VM_NAME}/g" /tmp/vm-config.yaml > /tmp/vm-config.yaml.$$

  sed -i "s/\${APP_NAME}/${VM_NAME}/g" /tmp/vm-config.yaml.$$

  ./oc create -f /tmp/vm-config.yaml.$$

  if [[ $? -eq 1 ]]; then echo "vm could not be created"; exit 1; fi

fi

./oc wait --for=condition=Ready vm ${VM_NAME} --timeout=900s

if [[ $? -eq 1 ]]; then echo "vm not ready on expected time"; exit 1; fi

./oc wait --for=condition=Ready vmi ${VM_NAME} --timeout=30s

if [[ $? -eq 1 ]]; then echo "vmi not ready on expected time"; exit 1;
fi

createService=0

./oc get svc ${VM_NAME}-ssh

if [[ $? -eq 1 ]]; then

  curl http://hyperconverged-cluster-cli-download.openshift-cnv.svc.cluster.local:8080/amd64/linux/virtctl.tar.gz -L -o virtctl.tar.gz

  tar zxvf virtctl.tar.gz

  chmod +x ./virtctl

  #You can use NodePort for SDN, LoadBalancer for OVN

  ./virtctl expose vmi ${VM_NAME} --port=22 --name=${VM_NAME}-ssh --type=LoadBalancer

  if [[ $? -eq 1 ]]; then echo "vmi could not be exposed"; exit 1; fi

  createService=1

fi

./oc get route ${VM_NAME}-ssh

if [[ $? -eq 1 ]]; then

  ./oc expose svc ${VM_NAME}-ssh

  if [[ $? -eq 1 ]]; then echo "ssh could not be exposed"; exit 1; fi

fi

url=$(./oc get route ${VM_NAME}-ssh -o jsonpath='{ .spec.host }')

echo -n $url > /tmp/hostname.${VM_NAME}

port=$(./oc get svc ${VM_NAME}-ssh -o jsonpath='{.spec.ports[].nodePort}')

if [[ $createService -eq 1 ]]; then

  #needed for OVN I think, allow externalIPs on Network config by admin

  externalIP=$(python -c "import socket;print(socket.gethostbyname(\"$url\"))")

  ./oc patch svc ${VM_NAME}-ssh --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/port", "value": '$port'}]'

  ./oc patch svc ${VM_NAME}-ssh --type='json' -p='[{"op": "add", "path": "/spec/externalIPs", "value": ["'$externalIP'"]}]'

fi

echo -n $port > /tmp/port.${VM_NAME}
