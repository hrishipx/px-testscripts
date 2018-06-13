#!/bin/bash

createSc() {
 echo $(pwd)  
kubectl apply -f groupsnaps/sc/sc.yaml
}

deleteSC() {
  echo $(pwd)
  kubectl delete -f groupsnaps/sc/sc.yaml
}

case "$1" in
        create)
                COMMAND=$1
                ;;
        cleanup)
                COMMAND=$1
                ;;
        *)
                echo "?Invalid command $1"
                show_usage
                ;;
esac

case "$COMMAND" in
        create)
             createSc
        ;;
        cleanup)
             deleteSC
        ;;
esac
