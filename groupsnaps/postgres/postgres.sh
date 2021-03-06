#!/bin/bash

NAMESPACE=$1
fatal() {
  echo "" 2>&1
  echo "$@" 2>&1
  exit 1
}

cat<< eof | kubectl apply -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
   name: postgres-data-${NAMESPACE}
   namespace: ${NAMESPACE}
   labels:
    tier: prod
    name: db
    app: postgres
   annotations:
     volume.beta.kubernetes.io/storage-class: px-postgres-sc-repl3-snap90
spec:
   accessModes:
     - ReadWriteOnce
   resources:
     requests:
       storage: 1Gi
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: postgres-${NAMESPACE}
  namespace: ${NAMESPACE}
spec:
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  replicas: 1
  template:
    metadata:
      labels:
        app: postgres-${NAMESPACE}
    spec:
      schedulerName: stork    
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: px/enabled
                operator: NotIn
                values:
                - "false"
      containers:
      - name: postgres
        image: postgres:9.5
        imagePullPolicy: "IfNotPresent"
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          value: pgbench
        - name: POSTGRES_PASSWORD
          value: superpostgres
        - name: PGBENCH_PASSWORD
          value: superpostgres
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - mountPath: /var/lib/postgresql/data
          name: postgredb
      volumes:
      - name: postgredb
        persistentVolumeClaim:
          claimName: postgres-data-${NAMESPACE}
eof

