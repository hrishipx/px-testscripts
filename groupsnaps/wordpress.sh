#!/bin/bash

kubectl create secret generic mysql-pass --from-literal=password=password

cat << eof | kubectl apply -f -
apiVersion: storage.k8s.io/v1beta1
kind: StorageClass
metadata:
  name: portworx-sc-repl3
provisioner: kubernetes.io/portworx-volume
parameters:
  repl: "3"
  priority_io: "high"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc-1
  labels: 
    tier: prod
    name: db
    app: mysql
  annotations:
    volume.beta.kubernetes.io/storage-class: portworx-sc-repl3
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
---
apiVersion: storage.k8s.io/v1beta1
kind: StorageClass
metadata:
  name: portworx-sc-repl3-shared
provisioner: kubernetes.io/portworx-volume
parameters:
  repl: "3"
  priority_io: "high"
  shared: "true"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wp-pv-claim
  labels:
    tier: prod
    name: db  
    app: wordpress
  annotations:
    volume.beta.kubernetes.io/storage-class: portworx-sc-repl3-shared
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress-mysql
  labels:
    app: wordpress
spec:
  ports:
    - port: 3306
  selector:
    app: wordpress
    tier: mysql
  clusterIP: None
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: wordpress-mysql
  labels:
    app: wordpress
spec:
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: wordpress
        tier: mysql
    spec:
      # Use the stork scheduler to enable more efficient placement of the pods
      schedulerName: stork
      containers:
      - image: mysql:5.6
        imagePullPolicy: 
        name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: password
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-persistent-storage
        persistentVolumeClaim:
          claimName: mysql-pvc-1
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  ports:
    - port: 80
      nodePort: 30303
  selector:
    app: wordpress
    tier: frontend
  type: NodePort
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  replicas: 3
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: wordpress
        tier: frontend
    spec:
      # Use the stork scheduler to enable more efficient placement of the pods
      schedulerName: stork
      containers:
      - image: wordpress:4.8-apache
        name: wordpress
        imagePullPolicy: 
        env:
        - name: WORDPRESS_DB_HOST
          value: wordpress-mysql
        - name: WORDPRESS_DB_PASSWORD
          value: password
        ports:
        - containerPort: 80
          name: wordpress
        volumeMounts:
        - name: wordpress-persistent-storage
          mountPath: /var/www/html
      volumes:
      - name: wordpress-persistent-storage
        persistentVolumeClaim:
          claimName: wp-pv-claim
eof
