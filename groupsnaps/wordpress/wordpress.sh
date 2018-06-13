#!/bin/bash
NAMESPACE=$1

fatal() {
  echo "" 2>&1
  echo "$@" 2>&1
  exit 1
}

kubectl create secret -n $NAMESPACE generic mysql-pass --from-literal=password=password
kubectl apply -f wp.yaml -n $NAMESPACE

