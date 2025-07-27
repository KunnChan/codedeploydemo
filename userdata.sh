#!/bin/bash

# System update
yum update -y

# Install Java (Amazon Corretto 21)
yum install -y java-21-amazon-corretto

# Set JAVA_HOME and update PATH system-wide
cat <<EOF > /etc/profile.d/java.sh
export JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto
export PATH=\$JAVA_HOME/bin:\$PATH
EOF

chmod +x /etc/profile.d/java.sh
source /etc/profile.d/java.sh


# Install CodeDeploy agent
yum install ruby wget -y
cd /home/ec2-user
wget https://aws-codedeploy-ap-southeast-1.s3.amazonaws.com/latest/install
chmod +x ./install
./install auto

# Start and enable CodeDeploy agent
systemctl start codedeploy-agent
systemctl enable codedeploy-agent

# Create app folder for deployment
mkdir -p /home/ec2-user/app
chown ec2-user:ec2-user /home/ec2-user/app
