# ansible-lamp

Pre-Requisites
**************

Create a secret for git accès :

```yaml
apiVersion: v1
data:
  accessToken: ...
  user: ...
kind: Secret
metadata:
  annotations:
    apps.open-cluster-management.io/deployables: "true"
  name: github-poc-ocp-0321
type: Opaque
```
and a secret for ansible-tower :

```yaml
kind: Secret
apiVersion: v1
metadata:
  annotations:
    apps.open-cluster-management.io/deployables: "true"
  name: tower-secret
data:
  password: ...
type: Opaque
```

On the namespace where you are going to deploy the application

