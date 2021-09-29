# quickstart-ibm-mq
## IBM MQ on the AWS Cloud

This Quick Start automatically deploys a highly available, production-ready IBM MQ server on the Amazon Web Services (AWS) Cloud in about 30 minutes, into a configuration of your choice.

IBM MQ is messaging middleware that simplifies and accelerates the integration of diverse applications and business data across multiple platforms. It uses message queues to facilitate the exchange of information, and offers a single messaging solution for cloud, mobile, the Internet of Things (IoT), and on-premises environments. The IBM MQ service on AWS will support client messaging applications from within your VPC, from trusted addresses on the Internet, and via a VPN from your on-premises environment.

This Quick Start uses AWS CloudFormation templates to deploy IBM MQ into a virtual private cloud (VPC) in your AWS account. You can build a new VPC for IBM MQ, or deploy the software into your existing VPC. The automated deployment provisions an Amazon Elastic Compute Cloud (Amazon EC2) instance running IBM MQ in an Auto Scaling group, Amazon Elastic File System (Amazon EFS) for distributed storage, and Elastic Load Balancing to automatically distribute connections to the active IBM MQ server. You can also use the AWS CloudFormation templates as a starting point for your own implementation.

![Quick Start architecture for IBM MQ on AWS](https://d0.awsstatic.com/partner-network/QuickStart/datasheets/ibm-mq-architecture-on-aws.png)

For architectural details, best practices, step-by-step instructions, and customization options, see the [deployment guide](https://fwd.aws/z5x65).

To post feedback, submit feature ideas, or report bugs, use the **Issues** section of this GitHub repo.
If you'd like to submit code for this Quick Start, please review the [AWS Quick Start Contributor's Kit](https://aws-quickstart.github.io/). 
