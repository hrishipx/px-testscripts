#!/bin/bash
NUM_NAMESPACES=15

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

setupStorageClasses(){
  echo "Create Storageclasses...."
  ./storageclasses.sh create
}

deleteStorageClasses(){
  echo "Cleanup Storageclasses....."
  ./sc/storageClasses.sh cleanup
}


deleteNamespaces(){
 for ((namespace=0; namespace < $NUM_NAMESPACES; namespace++ ))
 do
   kubectl delete ns ns-$namespace
 done;
}

createNamespaces(){
 for ((namespace=0; namespace < $NUM_NAMESPACES; namespace++ ))
 do
   kubectl create namespace ns-$namespace
 done;
}

installApps(){
  createPostgres
  #createWordpress
}
createPostgres() {
     echo "Deploying Postgres... in ns-$namespace"
    ./postgres/postgres.sh ns-$namespace
}

createWordpress(){
    echo "Deploying Wordpress... in ns-$namespace"
   ./wordpress/wordpress.sh ns-$namespace
}
setup(){
  createStorageClasses
  createNamespaces
  deployApps
}

tearDown(){
  deleteStorageClasses
  deleteNamespaces
}

deployApps(){

 for ((namespace=0; namespace < $NUM_NAMESPACES; namespace++ ))
 do
  installApps 
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
