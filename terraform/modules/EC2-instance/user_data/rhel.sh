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

#-------------------------------------------
# Enable SSH password authentication
#-------------------------------------------
echo "Configuring SSH password authentication..."

# Backup the original sshd_config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Configure SSH for password authentication - be explicit about all settings
cat >> /etc/ssh/sshd_config << 'EOF'

# Enable password authentication
PasswordAuthentication yes
ChallengeResponseAuthentication yes
PubkeyAuthentication yes
AuthenticationMethods publickey,password publickey password
PermitRootLogin yes
EOF

# Also use sed to ensure existing lines are updated
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# Restart SSH service to apply changes
systemctl restart sshd
echo "SSH password authentication enabled and service restarted."

# Verify SSH configuration
echo "Verifying SSH configuration:"
grep -E "^PasswordAuthentication|^ChallengeResponseAuthentication|^PubkeyAuthentication|^PermitRootLogin" /etc/ssh/sshd_config

# Test SSH service status
systemctl status sshd --no-pager

# Show active SSH configuration
echo "Active SSH configuration:"
sshd -T | grep -E "passwordauthentication|challengeresponseauthentication|pubkeyauthentication"
