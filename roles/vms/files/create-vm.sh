        #!/usr/bin/env bash

        curl http://downloads.openshift-console:80/amd64/linux/oc.tar -o oc.tar

        tar xvf oc.tar 

        ./oc get vm $(params.vm)

        if [[ $? -eq 1 ]]; then

          sed "s/\${VM_NAME}/$(params.vm)/g" /var/configmap/vm-config.yaml > /var/share/vm-config.yaml

          sed -i "s/\${APP_NAME}/$(params.app)/g" /var/share/vm-config.yaml

          ./oc create -f /var/share/vm-config.yaml

          if [[ $? -eq 1 ]]; then echo "vm could not be created"; exit 1; fi

        fi

        ./oc wait --for=condition=Ready vm $(params.vm) --timeout=900s

        if [[ $? -eq 1 ]]; then echo "vm not ready on expected time"; exit 1; fi

        ./oc wait --for=condition=Ready vmi $(params.vm) --timeout=30s

        if [[ $? -eq 1 ]]; then echo "vmi not ready on expected time"; exit 1;
        fi

        createService=0

        ./oc get svc $(params.vm)-ssh

        if [[ $? -eq 1 ]]; then

          curl http://hyperconverged-cluster-cli-download.openshift-cnv.svc.cluster.local:8080/amd64/linux/virtctl.tar.gz -L -o virtctl.tar.gz

          tar zxvf virtctl.tar.gz

          chmod +x ./virtctl

          #You can use NodePort for SDN, LoadBalancer for OVN
          
          ./virtctl expose vmi $(params.vm) --port=22 --name=$(params.vm)-ssh --type=LoadBalancer

          if [[ $? -eq 1 ]]; then echo "vmi could not be exposed"; exit 1; fi

          createService=1
          
        fi

        ./oc get route $(params.vm)-ssh

        if [[ $? -eq 1 ]]; then

          ./oc expose svc $(params.vm)-ssh

          if [[ $? -eq 1 ]]; then echo "ssh could not be exposed"; exit 1; fi

        fi

        url=$(./oc get route $(params.vm)-ssh -o jsonpath='{ .spec.host }')

        echo -n $url > $(results.hostname.path)

        port=$(./oc get svc $(params.vm)-ssh -o jsonpath='{
        .spec.ports[].nodePort}')

        if [[ $createService -eq 1 ]]; then

          #needed for OVN I think, allow externalIPs on Network config by admin

          externalIP=$(python -c "import socket;print(socket.gethostbyname(\"$url\"))")

          ./oc patch svc $(params.vm)-ssh --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/port", "value": '$port'}]'

          ./oc patch svc $(params.vm)-ssh --type='json' -p='[{"op": "add", "path": "/spec/externalIPs", "value": ["'$externalIP'"]}]'

        fi

        echo -n $port > $(results.sshport.path)
