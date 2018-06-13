#!/bin/bash
NUM_NAMESPACES=5

# derived from https://gist.github.com/davejamesmiller/1965569
ask() {
  # https://djm.me/ask
  local prompt default reply
  if [ "${2:-}" = "Y" ]; then
    prompt="Y/n"
    default=Y
  elif [ "${2:-}" = "N" ]; then
    prompt="y/N"
    default=N
  else
    prompt="y/n"
    default=
  fi

  # Ask the question (not using "read -p" as it uses stderr not stdout)<Paste>
  echo -n "$1 [$prompt]:"

  # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
  read reply </dev/tty
  if [ $? -ne 0 ]; then
    fatal "ERROR: Could not ask for user input - please run via interactive shell"
  fi

  # Default? (e.g user presses enter)
  if [ -z "$reply" ]; then
    reply=$default
  fi

  # Check if the reply is valid
  case "$reply" in
    Y*|y*) return 0 ;;
    N*|n*) return 1 ;;
    * )    echo "invalid reply: $reply"; return 1 ;;
  esac
}

show_usage() {

  echo ""
  echo "Setup Postgres on the cluster"
  echo ""
  echo "Options:"
  echo "         -n <number>        Number of namespaces to create and deploy postgres on"
  echo "  "
  echo "Commands:"
  echo "          create               Install a Postgres statefulset on the Kubernetes cluster."
  echo "          clean          Cleanup Postgres statefulset on the cluster."
   
  exit
}


deployPostgres() {
echo $namespace
kubectl create ns postgres-$namespace

cat << eof | kubectl apply -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1beta1
metadata:
    name: px-postgres-sc
provisioner: kubernetes.io/portworx-volume
parameters:
   repl: "2"
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
   name: postgres-data-$namespace
   namespace: postgres-$namespace
   labels:
    tier: prod
    name: db
    app: postgres-$namespace
   annotations:
     volume.beta.kubernetes.io/storage-class: px-postgres-sc
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
  name: postgres-$namespace
  namespace: postgres-$namespace
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
        app: postgres-$namespace
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
          claimName: postgres-data-$namespace
eof
}

cleanupPostgres(){
   kubectl delete ns postgres-$namespace
}


createPostgres(){

 echo "Deploying Postgres in $NUM_NAMESPACES" 
 for ((namespace=0; namespace < $NUM_NAMESPACES; namespace++ ))
 do
  deployPostgres 
 done;
}

cleanPostgres(){
  for ((namespace=0; namespace < $NUM_NAMESPACES; namespace++ ))
  do
   cleanupPostgres
  done;
}

OPTIONS=
while getopts "n:" opt; do
  case $opt in
  n ) NUM_NAMESPACES="$OPTARG";; 
  \? ) show_usage;;
  esac
done

shift "$((OPTIND-1))"
if [ $# -lt 1 ]; then 
        echo "?specify create or cleanup command"
        show_usage
fi

case "$1" in
        create)
                COMMAND=$1
                ;;
        clean)
                COMMAND=$1
                ;;
        *)
                echo "?Invalid command $1"
                show_usage
                ;;
esac

case "$COMMAND" in
        create)
             createPostgres
        ;;
        clean)
             cleanPostgres
        ;;
esac
