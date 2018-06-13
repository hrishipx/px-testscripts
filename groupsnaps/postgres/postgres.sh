#!/bin/bash


NAMESPACE=$1
fatal() {
  echo "" 2>&1
  echo "$@" 2>&1
  exit 1
}

kubectl apply -f postgres.yaml -n $NAMESPACE
