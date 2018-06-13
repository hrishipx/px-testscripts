#!/bin/bash

createSc() {
  kubectl apply -f sc.yaml
}

deleteSC() {
  kubectl delete -f sc.yaml
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
        clean)
             deleteSC
        ;;
esac