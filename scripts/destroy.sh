#!/bin/bash
# *********************************************************************
# * IBM Confidential
# * OCO Source Materials
# *
# * Copyright IBM Corp. 2022
# *
# * The source code for this program is not published or otherwise
# * divested of its trade secrets, irrespective of what has been
# * deposited with the U.S. Copyright Office.
# *********************************************************************
set -o pipefail
CUR_DIR="$(cd $(dirname $0) && pwd)"
source $CUR_DIR/ibm-mq-parameters.properties

export AWS_DEFAULT_REGION

if eksctl get cluster "${EKS_CLUSTER_NAME}"; then
    echo "Deleting cluster ${EKS_CLUSTER_NAME}..."
    eksctl delete cluster --wait "${EKS_CLUSTER_NAME}"
else
    echo "Cluster ${EKS_CLUSTER_NAME} does not exist."
fi
