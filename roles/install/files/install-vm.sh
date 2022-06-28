#!/usr/bin/env bash

export VM_NAME=$1
export PLAYBOOK=$2 
export EXTRA_ARGS=$3

AAP_PASSWORD=hpe-redhat

VM_HOSTNAME=`cat /tmp/hostname.${VM_NAME}`
SSH_PORT=`cat /tmp/port.${VM_NAME}`

awx --conf.host http://aap-controller-service.ansible.svc.cluster.local \
--conf.username hpe-redhat --conf.password ${AAP_PASSWORD} \
--conf.insecure inventory delete --name ${VM_NAME} \
--organization RedHat

awx --conf.host http://aap-controller-service.ansible.svc.cluster.local \
--conf.username hpe-redhat --conf.password ${AAP_PASSWORD} \
--conf.insecure inventory create --name ${VM_NAME} \
--organization RedHat

awx --conf.host http://aap-controller-service.ansible.svc.cluster.local \
--conf.username hpe-redhat --conf.password ${AAP_PASSWORD} \
--conf.insecure hosts create --name ${VM_HOSTNAME} --inventory \
${VM_NAME} --variables \
'{"ansible_port":${SSH_PORT},"ansible_connection":"ssh","ansible_user":"cloud-user","ansible_ssh_pass":"rhpoc"}'

awx --conf.host http://aap-controller-service.ansible.svc.cluster.local \
--conf.username hpe-redhat --conf.password ${AAP_PASSWORD} \
--conf.insecure job_templates launch repos --credentials "cle ssh" \
--inventory ${VM_NAME} --monitor ${EXTRA_ARGS}

awx --conf.host http://aap-controller-service.ansible.svc.cluster.local \
--conf.username hpe-redhat --conf.password ${AAP_PASSWORD} \
--conf.insecure job_templates launch ${PLAYBOOK} --credentials \
"cle ssh" --inventory ${VM_NAME} --monitor ${EXTRA_ARGS}
