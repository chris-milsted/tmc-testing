#!/bin/bash


#Licensed to the Apache Software Foundation (ASF) under one
#or more contributor license agreements.  See the NOTICE file
#distributed with this work for additional information
#regarding copyright ownership.  The ASF licenses this file
#to you under the Apache License, Version 2.0 (the
#"License"); you may not use this file except in compliance
#with the License.  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing,
#software distributed under the License is distributed on an
#"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#KIND, either express or implied.  See the License for the
#specific language governing permissions and limitations
#under the License.

#set a usage logic

print_usage() {
  echo "Usage:"
  echo "    $0  -n [cluster name] -i [kind image]"
  echo ""

}

check_binaries() {
  echo "Checking $1"
  if ! type $1 &> /dev/null; then 
    echo "$1 is required but not installed. Aborting"
    exit 1
  fi
}

check_environmental_variable() {
  local cluster_name="$1"
  echo "Checking proxy env variables"
  echo "Checking http proxy env variable"  
  if [ "$HTTP_PROXY" == "" ] && [ "$http_proxy" == "" ]; then
    echo "Neither \$HTTP_PROXY and \$http_proxy is set, please set \$HTTP_PROXY or \$http_proxy, exiting"
    exit 1
  fi

  echo "Checking https proxy env variable"
  if [ "$HTTPS_PROXY" == "" ] && [ "$https_proxy" == "" ]; then
    echo "Neither \$HTTPS_PROXY and \$https_proxy is set, please set \$HTTPS_PROXY or \$https_proxy, exiting"
    exit 1
  fi
}



# main logic start here
if [ "$#" -eq 0 ]; then
  echo "No arguement is taken, using cluster name 'proxy-cluster' and default 'kindest/node:v1.20.2' image"
  echo "Please check usage to confirm use case"
  print_usage
  read -n 1 -s -p "Press y to continue other keys to abort" key
  if [ "$key" != "y" ]; then
    exit 1
  fi
fi

cluster_name='proxy-cluster'
kind_image='kindest/node:v1.20.2'
invalid=1
while getopts 'n:i:' flag; do
  case "${flag}" in
    n) cluster_name=${OPTARG} ;;
    i) kind_image="${OPTARG}" ;;
    *) error "Unexpected option ${flag}" 
    invalid=0
    ;;
  esac
done

if [ "$invalid" -eq "0" ]; then
  echo "Invalid flag, exiting"
  exit 1
fi

check_binaries kind
check_binaries kubectl
check_environmental_variable "$cluster_name"

echo "Creating kind cluster with proxy"
if [ "$no_proxy" != "" ] && [ "$NO_PROXY" == "" ]; then
  no_proxy="${cluster_name}-control-plane,$no_proxy" kind create cluster --name ${cluster_name} --image ${kind_image} --retain
else
  NO_PROXY="${cluster_name}-control-plane,$NO_PROXY" kind create cluster --name ${cluster_name} --image ${kind_image} --retain
fi

kubectl config use-context kind-${cluster_name}

echo "Set up is done, please use 'tanzu management-cluster create --use-existing-bootstrap-cluster --ui' to create management cluster"
