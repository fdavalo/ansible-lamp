#!/usr/bin/env bash

export VM_NAME=$1
export PLAYBOOK = $2 
export SSH_PORT = $3
export EXTRA_ARGS = $4


awx --conf.host http://aap-controller-service.ansible.svc.cluster.local 
--conf.username hpe-redhat --conf.password ${AAP_PASSWORD}
--conf.insecure inventory delete --name ${VM_NAME}
--organization RedHat

awx --conf.host http://aap-controller-service.ansible.svc.cluster.local 
--conf.username hpe-redhat --conf.password ${AAP_PASSWORD}
--conf.insecure inventory create --name ${VM_NAME}
--organization RedHat

awx --conf.host http://aap-controller-service.ansible.svc.cluster.local 
--conf.username hpe-redhat --conf.password ${AAP_PASSWORD}
--conf.insecure hosts create --name ${VM_NAME} --inventory
${VM_NAME} --variables
'{"ansible_port":${SSH_PORT},"ansible_connection":"ssh","ansible_user":"cloud-user","ansible_ssh_pass":"rhpoc"}'

awx --conf.host http://aap-controller-service.ansible.svc.cluster.local 
--conf.username hpe-redhat --conf.password ${AAP_PASSWORD}
--conf.insecure job_templates launch repos --credentials "cle ssh"
--inventory ${VM_NAME} --monitor ${EXTRA_ARGS}

awx --conf.host http://aap-controller-service.ansible.svc.cluster.local 
--conf.username hpe-redhat --conf.password ${AAP_PASSWORD}
--conf.insecure job_templates launch ${PLAYBOOK} --credentials
"cle ssh" --inventory ${VM_NAME} --monitor ${EXTRA_ARGS}
