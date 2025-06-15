#!/bin/bash

#-------------------------------------------
# Detect system architecture
#-------------------------------------------
ARCH=$(uname -m)
echo "System architecture detected: $ARCH"

#-------------------------------------------
# Check if SSM Agent is installed; if not, install the correct architecture package
#-------------------------------------------
if ! command -v amazon-ssm-agent &> /dev/null; then
    echo "SSM Agent is not installed. Installing..."

    if [ "$ARCH" == "x86_64" ]; then
        sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    elif [ "$ARCH" == "aarch64" ]; then
        sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm
    else
        echo "Unsupported architecture: $ARCH"
    fi

    echo "SSM Agent installed successfully."
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    echo "SSM Agent service started and enabled."
    systemctl status amazon-ssm-agent
    echo "SSM Agent status checked."
else
    echo "SSM Agent is already installed."
fi

#-------------------------------------------
# Check if AWS CLI is installed; if not, install it
#-------------------------------------------
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Installing..."
    yum install -y aws-cli
    echo "AWS CLI installed successfully."
else
    echo "AWS CLI is already installed."
fi

#-------------------------------------------
# Set instance time zone to EST
#-------------------------------------------
timedatectl set-timezone America/New_York
echo "Time zone set to America/New_York."

#-------------------------------------------
# Check if Docker is installed; if not, install it
#-------------------------------------------
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing..."
    amazon-linux-extras install -y docker
    echo "Docker installed successfully."
    systemctl enable docker
    systemctl start docker
    echo "Docker service started and enabled."
    systemctl status docker
    echo "Docker status checked."
else
    echo "Docker is already installed."
fi
