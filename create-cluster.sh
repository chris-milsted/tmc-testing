#!/bin/bash
set -e
#This script is provided as an example and is provided as-is
# no warranty or liability will be accepted for the use of this

# Get your refresh token from console.cloud.vmware.com
API_TOKEN="FILL-IN-HERE"

# Your API endpoint, if you are logged into the TMC UI it is the URL shown in your browser
API_ENDPOINT=https://YOUR-ORG-HERE.tmc.cloud.vmware.com

# Find the CSP endpoint
CSP_ENDPOINT=https://console.cloud.vmware.com

# Aquire access token from CSP. This lasts 30 minutes by default. It's a standard JWT: examine it at jwt.io
CSP_ACCESS_TOKEN=$(curl -sSX POST "${CSP_ENDPOINT}/csp/gateway/am/api/auth/api-tokens/authorize?refresh_token=${API_TOKEN}" | jq -r .access_token)

# verify the token is working by listing all attached clusters
echo List of cluster groups
curl -sSX GET -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" ${API_ENDPOINT}/v1alpha1/clustergroups
echo

echo List of clusters
curl -sSX GET -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" ${API_ENDPOINT}/v1alpha1/clusters | jq -r .clusters[].fullName.name
echo

# Find name of first cluster
cluster_full_name=`curl -sSX GET -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" ${API_ENDPOINT}/v1alpha1/clusters | jq -r .clusters[0].fullName`
echo First cluster is: $cluster_full_name
echo

cluster_name=$(echo $cluster_full_name | jq -r .name)
cluster_management_cluster_name=$(echo $cluster_full_name | jq -r .managementClusterName)
cluster_provisioner_name=$(echo $cluster_full_name | jq -r .provisionerName)

# Show details of first cluster
curl -sSX GET -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" "${API_ENDPOINT}/v1alpha1/clusters/${cluster_name}?full_name.managementClusterName=${cluster_management_cluster_name}&full_name.provisionerName=${cluster_provisioner_name}" | jq .
echo

# Show IAM policies for first cluster
curl -sSX GET -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" "${API_ENDPOINT}/v1alpha1/clusters:iam/${cluster_name}?full_name.managementClusterName=${cluster_management_cluster_name}&full_name.provisionerName=${cluster_provisioner_name}" | jq .

# Show cluster options. These values can be used to determine avaiable regions, ssh keys, instance, etc.
echo List cluster options for first aws-hosted provisioner/account we find
provisioner_name=$(curl -sSX GET -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" ${API_ENDPOINT}/v1alpha1/managementclusters/aws-hosted/provisioners | jq -r .provisioners[0].fullName.name)
account_name=$(curl -sSX GET -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" "${API_ENDPOINT}/v1alpha1/account/managementcluster/provisioner/credentials?includeTotalCount=false&searchScope.managementClusterName=aws-hosted&searchScope.provisionerName=${provisioner_name}" | jq -r .credentials[0].fullName.name)
curl -sSX GET -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" "${API_ENDPOINT}/v1alpha1/clusters:options?managementClusterName=aws-hosted&credentialName=${account_name}&provisionerName=${provisioner_name}" | jq .

# Create a cluster. These are hardcoded but could be extracted from the previous requests
NEW_CLUSTERNAME="test"
CLUSTER_GROUP="default"
PROVISIONER_NAME="my-provisioner"
ACCOUNT_NAME="my-account"
SSH_KEY_NAME="my-ssh-key"

# Show cluster options for the configured hardcoded values
echo List cluster options for the configured values
curl -sSX GET -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" "${API_ENDPOINT}/v1alpha1/clusters:options?managementClusterName=aws-hosted&credentialName=${ACCOUNT_NAME}&provisionerName=${PROVISIONER_NAME}" | jq .

cat <<EOF > /tmp/create_request.json
{
  "cluster": {
    "fullName": {"name": "$NEW_CLUSTERNAME", "managementClusterName": "aws-hosted", "provisionerName": "$PROVISIONER_NAME"},
    "meta": {"description": "", "labels": {}},
    "spec": {
      "clusterGroupName": "$CLUSTER_GROUP",
      "tkgAws": {
        "distribution": {
          "provisionerCredentialName": "$ACCOUNT_NAME",
          "region": "us-east-1",
          "version":  "1.18.8-3-amazon2"
        },
        "settings": {
          "network": {
            "cluster": {
              "pods": [ { "cidrBlocks": "192.168.0.0/16" } ],
              "services": [ { "cidrBlocks": "10.96.0.0/12" } ]
            },
            "provider": { "vpc": { "cidrBlock": "10.0.0.0/16" } }
          },
          "security": { "sshKey": "$SSH_KEY_NAME" }
        },
        "topology": {
          "controlPlane": {
            "availabilityZones": [ "us-east-1a" ],
            "instanceType": "m5.large",
            "highAvailability": false
          },
          "nodePools": [
            {
              "spec": {
                "workerNodeCount": "1",
                "tkgAws": {
                  "instanceType": "m5.large",
                  "availabilityZone": "us-east-1a",
                  "version": "1.18.8-3-amazon2"
                }
              },
              "info": {
                  "name": "default-node-pool"
              }
            }
          ]
        }       
      }
    }
  }
}
EOF

# Here is an HA exmaple
# cat <<EOF > /tmp/create_request.json
# {
#   "cluster": {
#     "fullName": {"name": "$NEW_CLUSTERNAME", "managementClusterName": "aws-hosted", "provisionerName": "$PROVISIONER_NAME"},
#     "meta": {"description": "", "labels": {}},
#     "spec": {
#       "clusterGroupName": "$CLUSTER_GROUP",
#       "tkgAws": {
#         "distribution": {
#           "provisionerCredentialName": "$ACCOUNT_NAME",
#           "region": "us-east-1",
#           "version":  "1.18.8-3-amazon2"
#         },
#         "settings": {
#           "network": {
#             "cluster": {
#               "pods": [ { "cidrBlocks": "192.168.0.0/16" } ],
#               "services": [ { "cidrBlocks": "10.96.0.0/12" } ]
#             },
#             "provider": { "vpc": { "cidrBlock": "10.0.0.0/16" } }
#           },
#           "security": { "sshKey": "$SSH_KEY_NAME" }
#         },
#         "topology": {
#           "controlPlane": {
#             "availabilityZones": [ "us-east-1a, us-east-1b, us-east-1c" ],
#             "instanceType": "m5.large",
#             "highAvailability": true
#           },
#           "nodePools": [
#             {
#               "spec": {
#                 "workerNodeCount": "1",
#                 "tkgAws": {
#                   "instanceType": "m5.large",
#                   "availabilityZone": "us-east-1a",
#                   "version": "1.18.8-3-amazon2"
#                 }
#               },
#               "info": {
#                   "name": "default-node-pool"
#               }
#             }
#           ]
#         }       
#       }
#     }
#   }
# }
# EOF

echo Creating a new cluster
curl -sSX POST -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" -H 'content-type: application/json' -d @/tmp/create_request.json ${API_ENDPOINT}/v1alpha1/clusters | jq .

echo -n Waiting for cluster to become READY.
while $(curl -sSX GET -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" "${API_ENDPOINT}/v1alpha1/clusters/${NEW_CLUSTERNAME}?full_name.managementClusterName=aws-hosted&full_name.provisionerName=${PROVISIONER_NAME}" | jq -e '.cluster.status.phase == "READY"'); do
  echo -n .
  sleep 10
done
echo " Done!"
curl -sSX GET -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" "${API_ENDPOINT}/v1alpha1/clusters/${NEW_CLUSTERNAME}?full_name.managementClusterName=aws-hosted&full_name.provisionerName=${PROVISIONER_NAME}" | jq .


# Upgrade the cluster. Must wait until all of the nodepools are ready
# echo Upgrade the cluster by changing the version field in the Cluster spec
# curl -sSX GET -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" "${API_ENDPOINT}/v1alpha1/clusters/${NEW_CLUSTERNAME}?full_name.managementClusterName=aws-hosted&full_name.provisionerName=${PROVISIONER_NAME}" | jq '.cluster.spec.tkgAws.distribution.version = "1.19.3-1-amazon2"' > /tmp/upgrade_request.json
# curl -sSX PUT -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" -H 'content-type: application/json' -d @/tmp/upgrade_request.json "${API_ENDPOINT}/v1alpha1/clusters/${NEW_CLUSTERNAME}?full_name.managementClusterName=aws-hosted&full_name.provisionerName=${PROVISIONER_NAME}" | jq .

# echo -n Waiting for cluster to become READY after upgrade.
# while $(curl -sSX GET -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" "${API_ENDPOINT}/v1alpha1/clusters/${NEW_CLUSTERNAME}?full_name.managementClusterName=aws-hosted&full_name.provisionerName=${PROVISIONER_NAME}" | jq -e '.cluster.status.phase != "READY"'); do
#   echo -n .
#   sleep 10
# done
# echo " Done!"
# curl -sSX GET -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" "${API_ENDPOINT}/v1alpha1/clusters/${$NEW_CLUSTERNAME}?full_name.managementClusterName=aws-hosted&full_name.provisionerName=${PROVISIONER_NAME}" | jq .

# # Delete cluster
# echo Delete the cluster
# curl -sSX DELETE -H "Authorization: Bearer ${CSP_ACCESS_TOKEN}" "${API_ENDPOINT}/v1alpha1/clusters/${NEW_CLUSTERNAME}?full_name.managementClusterName=aws-hosted&full_name.provisionerName=${PROVISIONER_NAME}" | jq .
