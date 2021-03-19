#!/bin/bash
##################################
# Tanzu Migrator Kollector
# This tool collects information from a Kubernetes cluster in preparation for a migration to Tanzu Kubernetes Grid cluster.
##################################
# Copyright 2021 VMware - Technical Preview License
# https://flings.vmware.com/sample-data-platform-on-vmware-cloud-foundation-with-vmware-tanzu-for-kubernetes-provisioning/license
# WARRANTY DISCLAIMER:
# IT IS UNDERSTOOD THAT THE TECHNOLOGY PREVIEW SOFTWARE, OPEN SOURCE SOFTWARE, DOCUMENTATION, AND ANY UPDATES MAY CONTAIN ERRORS AND ARE PROVIDED FOR LIMITED EVALUATION ONLY.
# LIMITATION OF LIABILITY:
# IT IS UNDERSTOOD THAT THE TECHNOLOGY PREVIEW SOFTWARE IS PROVIDED WITHOUT CHARGE FOR LIMITED EVALUATION PURPOSES.
# ACCORDINGLY, THERE IS NO LIABILITY OF VMWARE AND ITS LICENSORS ARISING OUT OF OR RELATED TO THIS AGREEMENT.  
##################################
#
# ATTENTION: THIS TOOL DOES NOT COLLECT ANY SENSITIVE DATA SUCH AS PASSWORDS, SECRETS, CONFIGMAPS, TOKENS AND CERTIFICATES.
#
################################## 
set -e
#set -x
CURDIR=`pwd`
MYDIR=/tmp
TODAY=`date +%Y-%m-%d`
VERSION="Tanzu Migrator Kollector v0.2.0"
# API URL
MYHOST=`kubectl cluster-info 3>/dev/null |grep "Kubernetes master" | awk '{print $6}'|tr -d '[:space:]'`
NOW=`date +%Y-%m-%d-T%H%M%S`
printf   "INFO: $VERSION script starting to collect data at $NOW...\n" 

#Setup and error checking

# we need a kubectl
which kubectl &>/dev/null
if (( $? )) ; then
  printf  "ERROR: kubectl binary not found. Script exited!\n"
  exit 1
fi

# check connectivity with cluster API
kubectl cluster-info  &>/dev/null
if  (( $? )) ; then
  printf "ERROR: Make sure your cluster is up or you are logged in. Script exited!\n"
  exit 1
else
  printf "INFO: K8s API is ${MYHOST} and is ready...\n"
fi

KCONTEXT=`kubectl config current-context 2>/dev/null | awk '{print $1}'`

# OpenShift Cluster name has ":" on its name, parsing out
# using CLUSTER column from get-contexts
CLUNAME=`kubectl config get-contexts 2>/dev/null | grep $KCONTEXT | awk '{print $3}' | awk -F\: '{print $1}'`
# sometimes context is different from cluster name - example is OpenShift
printf  "INFO: Current cluster name is: ${CLUNAME}\n"
printf  "INFO: Current kubectl context is: ${KCONTEXT}\n"

if [ ${CLUNAME} = "" ]; then
  printf "ERROR: Cannot parse the cluster name from kubectl context. Exiting."
  exit 1
fi

KOLLECTORDIR=${MYDIR}/kollector/${CLUNAME}/${NOW}
printf  "INFO: Creating temporary directory at ${KOLLECTORDIR}\n" 
mkdir -p ${KOLLECTORDIR} 2>/dev/null
if [ ! -d  ${KOLLECTORDIR} ]; then
  printf "ERROR: Directory $KOLLECTORDIR cannot be created. Script exited!\n"
  exit 1
fi

cd ${KOLLECTORDIR}
LOGSTATIC=${KOLLECTORDIR}/${CLUNAME}"-cluster-summary".txt

printf  "INFO: Start collecting cluster summary information\n" 
printf  "INFO: Start collecting cluster summary information\n" >> ${LOGSTATIC}
runningPODs=`kubectl get pods -A --field-selector=status.phase=Running 2>/dev/null | grep -v NAME| wc -l|tr -d '[:space:]'`
numNameSpaces=`kubectl get namespaces -A  2>/dev/null| grep -v NAME| wc -l|tr -d '[:space:]'`
numPV=`kubectl get pv 2>/dev/null| grep -v NAME| wc -l|tr -d '[:space:]'`
numPVC=`kubectl get pvc -A 2>/dev/null| grep -v NAME| wc -l|tr -d '[:space:]'`
numSC=`kubectl get sc -A 2>/dev/null| grep -v NAME| wc -l|tr -d '[:space:]'`
numCRDs=`kubectl get crds -A 2>/dev/null| grep -v NAME|wc -l|tr -d '[:space:]'`
numNodes=`kubectl  get nodes 2>/dev/null| grep -v NAME| wc -l|tr -d '[:space:]'`
numMasters=`kubectl get node --selector='node-role.kubernetes.io/master' 2>/dev/null | grep -v NAME | wc -l|tr -d '[:space:]'`
numWorkers=`kubectl get node --selector='!node-role.kubernetes.io/master' 2>/dev/null| grep -v NAME | wc -l|tr -d '[:space:]'`
osImage=`kubectl get nodes -o wide  2>/dev/null| grep -v NAME| awk '{print $8, $9, $10}'| sort -u|tr -d '[:space:]'`
k8sVer=`kubectl get nodes -o wide 2>/dev/null  | grep -v NAME| awk '{print $5}' | sort -u|tr -d '[:space:]'`
storageProvisoner=`kubectl  describe sc | grep Provisioner | awk '{print $2}'|tr -d '[:space:]'`
numSVCs=`kubectl get services -A 2>/dev/null| grep -v NAME| wc -l|tr -d '[:space:]'`
numDeploy=`kubectl get deployments -A 3>/dev/null | grep -v NAME| wc -l|tr -d '[:space:]'`
numRoles=`kubectl get clusterroles -A 2>/dev/null| grep -v NAME| wc -l|tr -d '[:space:]'`
numPSPs=`kubectl get psp -A 2>/dev/null|grep -v NAME|wc -l|tr -d '[:space:]'`
numDCs=`kubectl get deploymentconfigs -A 2>/dev/null|grep -v NAME|wc -l|tr -d '[:space:]'`
numSCCs=`kubectl get scc -A 2>/dev/null|grep -v NAME|wc -l|tr -d '[:space:]'`
numRoutes=`kubectl get routes -A 2>/dev/null|grep -v NAME|wc -l|tr -d '[:space:]'`
numImageStreams=`kubectl get imagestreams  -A 2>/dev/null|grep -v NAME|wc -l|tr -d '[:space:]'`
printf "\n"
printf "\n" >> ${LOGSTATIC}
printf  "\tCluster Name\t:\t${CLUNAME}\n\tK8s API\t\t:\t${MYHOST}\n\tK8s Version\t:\t${k8sVer}\n\tOS-Image\t:\t${osImage}\n"
printf  "\tCluster Name\t:\t${CLUNAME}\n\tK8s API\t\t:\t${MYHOST}\n\tK8s Version\t:\t${k8sVer}\n\tOS-Image:\t${osImage}\n" >> ${LOGSTATIC}
printf  "\tNode Info\t:\tCluster Nodes ${numNodes}; MasterNodes ${numMasters}; WorkerNodes ${numWorkers};\n"
printf  "\tNode Info\t:\tCluster Nodes ${numNodes}; MasterNodes ${numMasters}; WorkerNodes ${numWorkers};\n" >> ${LOGSTATIC}
printf  "\tWorkload\t:\tNamespaces ${numNameSpaces}; Pods(Running) ${runningPODs};\n"
printf  "\tWorkload\t:\tNamespaces ${numNameSpaces}; Pods(Running) ${runningPODs};\n" >> ${LOGSTATIC}
printf  "\tStorage\t\t:\tPersistentVolumes ${numPV}; PersistentVolumeClaims ${numPVC}; StorageClasses ${numSC}; StorageProvisoner ${storageProvisoner};\n"
printf  "\tStorage\t\t:\tPersistentVolumes ${numPV}; PersistentVolumeClaims ${numPVC}; StorageClasses ${numSC}; StorageProvisoner ${storageProvisoner};\n" >> ${LOGSTATIC}
printf  "\tMiscInfo\t:\tCRDs ${numCRDs}; Services ${numSVCs}; Deployments ${numDeploy}; ClusterRoles ${numRoles}; PSPs ${numPSPs};\n"
printf  "\tMiscInfo\t:\tCRDs ${numCRDs}; Services ${numSVCs}; Deployments ${numDeploy}; ClusterRoles ${numRoles}; PSPs ${numPSPs};\n" >> ${LOGSTATIC}
printf  "\tOcpInfo\t\t:\tDeploymentConfigs ${numDCs}; Routes ${numRoutes}; SCCs ${numSCCs}; ImageStreams ${numImageStreams};\n\n"
printf  "\tOcpInfo\t\t:\tDeploymentConfigs ${numDCs}; Routes ${numRoutes}; SCCs ${numSCCs}; ImageStreams ${numImageStreams};\n\n" >> ${LOGSTATIC}
printf  "INFO: end collecting cluster summary information\n" >> ${LOGSTATIC}
printf  "INFO: end collecting cluster summary information, starting the detailed kollection...\n"

#Optional Pause For debuging
#read -p "INFO: Press [Enter] key to start collection..."

#API Stuff
mkdir -p ${KOLLECTORDIR}/cluster-apis/
printf  "INFO: start running command kubectl get --raw  /apis for cluster $CLUNAME at $NOW  ...\n"
kubectl get --raw  /apis -A >>  ${KOLLECTORDIR}/cluster-apis/${CLUNAME}-cluster-apis.yaml 

#full cluster dump
printf  "INFO: start running command kubectl cluster-info dump -o yaml for cluster $CLUNAME at $NOW  ...\n"
kubectl cluster-info dump -o yaml >>  ${KOLLECTORDIR}/${CLUNAME}-cluster-dump.yaml

printf  "INFO: start running command kubectl get nodes -o wide for cluster $CLUNAME at $NOW to file ...\n"
printf  "INFO: start running command kubectl get nodes -o wide for cluster $CLUNAME at $NOW to file ..\n." >> ${LOGSTATIC}
kubectl get nodes -o wide -A >> ${LOGSTATIC}
printf  "INFO: end running command kubectl get nodes -o wide for cluster $CLUNAME at $NOW to file ...\n" >> ${LOGSTATIC}

printf  "INFO: start running command kubectl get namespaces for cluster $CLUNAME at $NOW to file ...\n"
printf  "INFO: start running command kubectl get namespaces for cluster $CLUNAME at $NOW to file ...\n" >> ${LOGSTATIC}
kubectl get namespaces -A >> ${LOGSTATIC} 
printf  "INFO: end running command kubectl get namespaces for cluster $CLUNAME at $NOW to file ...\n" >> ${LOGSTATIC}

printf  "INFO: start running command kubectl get pods for cluster $CLUNAME on $TODAY at $NOW to file ...\n"
printf  "INFO: start running command kubectl get pods for cluster $CLUNAME on $TODAY at $NOW to file ...\n" >> ${LOGSTATIC}
kubectl get pods -A --field-selector=status.phase=Running  2>/dev/null >> ${LOGSTATIC}
printf  "INFO: end running command kubectl get pods for cluster $CLUNAME at $NOW to file ...\n" >> ${LOGSTATIC}

printf  "INFO: start running command kubectl get crds for cluster $CLUNAME at $NOW to file ...\n"
printf  "INFO: start running command kubectl get crds for cluster $CLUNAME at $NOW to file ...\n" >> ${LOGSTATIC}
kubectl get crds -A  2>/dev/null >> ${LOGSTATIC}
printf  "INFO: end running command kubectl get crds for cluster $CLUNAME at $NOW to file ...\n" >> ${LOGSTATIC}

printf  "INFO: start running command kubectl get pv --sort-by=.spec.capacity.storage - for cluster $CLUNAME at $NOW to file ...\n"
printf  "INFO: start running command kubectl get pv --sort-by=.spec.capacity.storage - for cluster $CLUNAME at $NOW to file ...\n" >> ${LOGSTATIC}
kubectl get pv -A --sort-by=.spec.capacity.storage  2>/dev/null >> ${LOGSTATIC}
printf  "INFO: end running command kubectl get persistent volumes for cluster $CLUNAME at $NOW to file ...\n" >> ${LOGSTATIC}

printf  "INFO: start running command kubectl get sc for cluster $CLUNAME at $NOW to file ...\n"
printf  "INFO: start running command kubectl get sc for cluster $CLUNAME at $NOW to file ...\n" >> ${LOGSTATIC}
kubectl get sc 2>/dev/null >> ${LOGSTATIC}
printf  "INFO: end running command kubectl get sc for cluster $CLUNAME at $NOW to file ...\n" >> ${LOGSTATIC}

printf  "INFO: start running command kubectl get psp for cluster $CLUNAME at $NOW to file ...\n"
printf  "INFO: start running command kubectl get psp for cluster $CLUNAME at $NOW to file ...\n" >> ${LOGSTATIC}
kubectl get psp 2>/dev/null >> ${LOGSTATIC};
printf  "INFO: end running command kubectl get psp for cluster $CLUNAME at $NOW to file ...\n" >> ${LOGSTATIC}

#SC stuff
#create bash array of Storage Classes
declare sc_array
sc_array=(`kubectl get sc 2>/dev/null | grep -v NAME |  awk '{print $1}'`)
mkdir -p ${KOLLECTORDIR}/cluster-scs/
printf  "INFO: start running command kubectl get sc  -o yaml\n"
for i in ${sc_array[@]}; do
        printf "INFO: exporting storage class $i to yaml file ${KOLLECTORDIR}/cluster-scs/$i.sc.yaml\n"
        kubectl get sc $i -A -o yaml >> ${KOLLECTORDIR}/cluster-scs/${i}.sc.yaml
done

#PSP Stuff
#create bash array of PSPs
declare psps_array
psps_array=(`kubectl get psp 2>/dev/null | grep -v NAME |  awk '{print $1}'`)
mkdir -p ${KOLLECTORDIR}/cluster-psps/
printf  "INFO: start running command kubectl get psp -o yaml\n"
for i in ${psps_array[@]}; do
        #printf "INFO: exporting pod security policy $i to yaml file ${KOLLECTORDIR}/cluster-psps/$i.psp.yaml\n"
        kubectl get psp $i -A -o yaml >> ${KOLLECTORDIR}/cluster-psps/${i}.psp.yaml
done

#CRD 
#create bash array of CRDS
declare crds_array
crds_array=(`kubectl get crds 2>/dev/null | grep -v NAME |  awk '{print $1}'`)
mkdir -p ${KOLLECTORDIR}/cluster-crds/
printf  "INFO: start running command kubectl get crds -o yaml - Please be patient\n"
for i in ${crds_array[@]}; do
	#printf "INFO: exporting CRD $i to yaml file ${KOLLECTORDIR}/cluster-crds/$i.yaml\n"
	kubectl get crd $i -o yaml > ${KOLLECTORDIR}/cluster-crds/${i}.yaml
done

#CRs
mkdir ${KOLLECTORDIR}/cluster-crs/
printf  "INFO: start running command kubectl to get all Custom Resources (CRs) - Please be patient, it may take minutes depending of the cluster\n"
for i in ${crds_array[@]}; do
        #printf "INFO: exporting crs $i to yaml file ${KOLLECTORDIR}/cluster-crs/$i.yaml\n"
        kubectl get $i -A -o yaml > ${KOLLECTORDIR}/cluster-crs/${i}.yaml
done

#CLUSTER ROLES
printf  "INFO: start running command kubectl get clusterroles for cluster $CLUNAME at $NOW to file ..\n." >> ${LOGSTATIC}
kubectl get clusterroles 2>/dev/null >> ${LOGSTATIC}
declare clusterroles_array
clusterroles_array=(`kubectl get clusterroles| grep -v NAME |  awk '{print $1}'`)
mkdir ${KOLLECTORDIR}/cluster-roles/
printf  "INFO: start running command kubectl get clusterroles -o yaml - Please be patient\n"
for i in ${clusterroles_array[@]}; do
        #printf "INFO: exporting cluster roles $i to yaml file ${KOLLECTORDIR}/cluster-roles/$i.cluster-roles.yaml\n"
        kubectl get clusterroles $i -A -o yaml >> ${KOLLECTORDIR}/cluster-roles/"$i.cluster-roles.yaml";
done
printf  "INFO: end running command kubectl get clusterroles for cluster $CLUNAME at $NOW to file ...\n" >> ${LOGSTATIC}

# Collecting objects in NameSpaces 
printf  "INFO: start running command kubectl get -o=custom-columns for cluster $CLUNAME at $NOW  ... - Please be patient\n"
printf  "INFO: start running command kubectl get -o=custom-columns=NAMESPACE:.metadata.namespace,OBJECT-TYPE:.kind,NAME:.metadata.name pvc,configmap,Ingress,service,deployment,statefulset,hpa,job,cronjob,networkpolicies,daemonsets --all-namespaces  for cluster $CLUNAME at $NOW  ...\n" >> ${LOGSTATIC}
kubectl get -o=custom-columns=NAMESPACE:.metadata.namespace,OBJECT-TYPE:.kind,NAME:.metadata.name pvc,configmap,Ingress,service,deployment,statefulset,hpa,job,cronjob,networkpolicies,daemonsets --all-namespaces >> ${LOGSTATIC}
printf  "INFO: end running command kubectl get -o=custom-columns=NAMESPACE:.metadata.namespace,OBJECT-TYPE:.kind,NAME:.metadata.name pvc,configmap,ingress,service,deployment,statefulset,hpa,job,cronjob,networkpolicies,daemonsets --all-namespaces  for cluster $CLUNAME at $NOW  ...\n" >> ${LOGSTATIC}
printf  "INFO: start running command kubectl get <object type -ns <namespace name> -o yaml - Please be patient\n"
i=$((0))
for n in $(kubectl get -o=custom-columns=NAMESPACE:.metadata.namespace,OBJECT-TYPE:.kind,NAME:.metadata.name pvc,Ingress,service,deployment,statefulset,hpa,job,cronjob,networkpolicies,daemonsets --all-namespaces)
	do
	if (( $i < 1 )); then
		namespace=$n
		i=$(($i+1))
		if [[ "$namespace" == "PersistentVolume" ]]; then
			kind=$n
			i=$(($i+1))
		fi
	elif (( $i < 2 )); then
		kind=$n
		i=$(($i+1))
	elif (( $i < 3 )); then
		name=$n
		i=$((0))
		#printf "INFO: exporting object  ${namespace} ${kind} ${name} to directory ${KOLLECTORDIR}/"namespaces"$namespace\n"
		if [[ "$namespace" != "NAMESPACE" ]]; then
			mkdir -p ${KOLLECTORDIR}/namespaces/$namespace
			kubectl get $kind $name -n $namespace -o yaml >>  ${KOLLECTORDIR}/namespaces/$namespace/$kind.$name.yaml

		fi
	fi
done	


# collecting and display message to cleanup
printf  "INFO: start command tar cvzf ${CURDIR}/${CLUNAME}-${NOW}.tgz ${KOLLECTORDIR}/\n"
tar czf ${CURDIR}/kollector-${CLUNAME}-${NOW}.tgz ${KOLLECTORDIR}/ &>/dev/null || printf "ERROR: Failed tar ${KOLLECTORDIR}\n"
NOW=`date +%Y-%m-%d-T%H%M%S`
printf  "INFO: $VERSION script ending data collection at $NOW...\n" 
printf  "#################################\n"
printf  "Please:\n\t1. Send tar file for review: ${CURDIR}/kollector-${CLUNAME}-${NOW}.tgz\n"
printf  "\t2. Remove manually the directory ${KOLLECTORDIR} if you wish.\n"
printf  "#################################\n"
