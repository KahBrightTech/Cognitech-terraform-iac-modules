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

#!/bin/bash
#-------------------------------------------
# Enable SSH password authentication - RHEL 9
#-------------------------------------------
echo "Configuring SSH password authentication..."

# Backup the original sshd_config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Remove any override that disables password authentication in /etc/ssh/sshd_config.d/*.conf
echo "Checking for overrides in /etc/ssh/sshd_config.d/..."
grep -Rl "^PasswordAuthentication no" /etc/ssh/sshd_config.d/ 2>/dev/null | while read -r file; do
    echo "Updating $file to enable password authentication"
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' "$file"
done

grep -Rl "^KbdInteractiveAuthentication no" /etc/ssh/sshd_config.d/ 2>/dev/null | while read -r file; do
    echo "Updating $file to enable keyboard-interactive authentication"
    sed -i 's/^KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' "$file"
done

# Append RHEL 9 settings to main sshd_config (if not already present)
cat >> /etc/ssh/sshd_config << 'EOF'

# Enable password authentication for RHEL 9
PasswordAuthentication yes
KbdInteractiveAuthentication yes
PubkeyAuthentication yes
PermitRootLogin yes
UsePAM yes
EOF

# Update existing lines in sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#*UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config

# Restart SSH service to apply changes
echo "Restarting SSH service..."
systemctl restart sshd

# Verify SSH configuration
echo "Verifying SSH configuration in main file:"
grep -E "^PasswordAuthentication|^KbdInteractiveAuthentication|^PubkeyAuthentication|^PermitRootLogin|^UsePAM" /etc/ssh/sshd_config

# Test SSH service status
systemctl status sshd --no-pager

# Show available users
echo "Available users:"
cut -d: -f1 /etc/passwd | grep -E "(ec2-user|ssm-user|root|Admin)"


