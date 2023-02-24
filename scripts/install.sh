#!/bin/bash
set -o pipefail
CUR_DIR="$(cd $(dirname $0) && pwd)"
source $CUR_DIR/ibm-mq-parameters.properties
source $CUR_DIR/utilities.sh

sudo yum install -y -q jq git

create_namespace() {
    namespace=$1

    if ! kubectl get namespace "${namespace}" >/dev/null; then
        echo "Creating the namespace '${namespace}'..."
        kubectl create namespace "${namespace}"
    else
        echo "The namespace ${namespace} already exists."
    fi
}

# Update aws cli: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# On the EC2 instance, out of the box, aws command is installed at /usr/bin/aws and is older version
#      aws --version => aws-cli/1.18.147 Python/2.7.18 Linux/4.14.231-173.361.amzn2.x86_64 botocore/1.18.6
# By default, (aws cli install) files are all installed to /usr/local/aws-cli, and a symbolic link is created in /usr/local/bin.
if ! aws --version | grep --color=never 'aws-cli/2'; then
    echo "Version 1 of the AWS CLI is installed. Updating to version 2."
    sudo rm -rf `which aws`
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscli_new.zip"
    unzip -u -q awscli_new.zip
    sudo ./aws/install
    export PATH=/usr/local/bin:${PATH}
    echo "Updated aws cli version:" `aws --version`
fi

# Update the .kube/config file to access the cluster with kubectl
echo "aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME}"
aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME}

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo "kubectl version: " `kubectl version`

# Install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# EKS setup - OIDC provider, Service Account, EBS CSI driver
eksctl utils associate-iam-oidc-provider --region=$AWS_DEFAULT_REGION --cluster=$EKS_CLUSTER_NAME --approve
eksctl create iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system --cluster $EKS_CLUSTER_NAME --region $AWS_DEFAULT_REGION --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --approve --role-only --role-name AmazonEKS_EBS_CSI_DriverRole_${EKS_CLUSTER_NAME: -10}-$AWS_DEFAULT_REGION
AWS_ACCOUNT_ID=$(aws sts get-caller-identity | jq -r '.Account')
eksctl create addon --name aws-ebs-csi-driver --cluster $EKS_CLUSTER_NAME --region $AWS_DEFAULT_REGION --service-account-role-arn  arn:aws:iam::$AWS_ACCOUNT_ID:role/AmazonEKS_EBS_CSI_DriverRole_${EKS_CLUSTER_NAME: -10}-$AWS_DEFAULT_REGION --force

# Wait for addon to become active
check_addon_active $EKS_CLUSTER_NAME $AWS_DEFAULT_REGION

# Create the APPLICATION_NAMESPACE if it doesn't exist
echo "Creating namespaces..."
if [[ -n "${APPLICATION_NAMESPACE}" && "${APPLICATION_NAMESPACE,,}" != "default" ]]; then
    create_namespace "${APPLICATION_NAMESPACE}"
fi

# Install MQ helm chart
echo "Installing IBM MQ helm chart..."
cd $CUR_DIR/..
git clone --depth 1 --branch main https://github.com/ibm-messaging/mq-helm.git
cd mq-helm/samples/AWSEKS/deploy/
./install.sh $APPLICATION_NAMESPACE $ADMIN_PASSWORD $APP_PASSWORD

#Wait 2 minutes for POD to be in a running state
sleep 120
export CONSOLE_PORT=9443
export CONSOLE_IP=$(kubectl get services secureapphelm-ibm-mq-loadbalancer -n mq-ha -o jsonpath="{..hostname}")
export MQ_URL=$(echo https://$CONSOLE_IP:$CONSOLE_PORT/ibmmq/console)
aws ssm put-parameter --name $MQURL_SSM_PARAMETER --value $MQ_URL --type String --overwrite

#Deleting passwords from text file:
sed -i '/_PASSWORD/d' $CUR_DIR/ibm-mq-parameters.properties

sudo shutdown +2 "IBM MQ installation is complete. \
#The system will now shut down in 2 minutes. If you are currently \
#using this system, run 'sudo shutdown -c' to stop the shutdown."
