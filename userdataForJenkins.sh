#!/bin/bash
# ---------------------------
# Update OS
# ---------------------------
yum update -y

# ---------------------------
# Install Java 21 (Amazon Corretto)
# ---------------------------
yum install -y java-21-amazon-corretto

# ---------------------------
# Install Git and build tools
# ---------------------------
yum install -y git wget unzip

# ---------------------------
# Install Maven (Latest stable from Apache)
# ---------------------------
cd /opt
wget https://downloads.apache.org/maven/maven-3/3.9.11/binaries/apache-maven-3.9.11-bin.tar.gz
tar -xvzf apache-maven-3.9.11-bin.tar.gz
# Create symbolic link for easier upgrades in future
ln -s apache-maven-3.9.11 maven

# Set environment variables for Maven
echo "export M2_HOME=/opt/maven" >> /etc/profile.d/maven.sh
echo "export PATH=\$M2_HOME/bin:\$PATH" >> /etc/profile.d/maven.sh
chmod +x /etc/profile.d/maven.sh

# Apply the environment variables for current session
source /etc/profile.d/maven.sh

# ---------------------------
# Install Jenkins (latest stable)
# ---------------------------
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum install -y jenkins

# ---------------------------
# Enable and start Jenkins
# ---------------------------
systemctl enable jenkins
systemctl start jenkins

# ---------------------------
# Optional: Add swap (for low-memory EC2)
# ---------------------------
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# ---------------------------
# Log version info
# ---------------------------
echo "Java Version:" >> /var/log/userdata.log
java -version >> /var/log/userdata.log 2>&1

echo "Node Version:" >> /var/log/userdata.log
node -v >> /var/log/userdata.log

echo "NPM Version:" >> /var/log/userdata.log
npm -v >> /var/log/userdata.log

echo "Maven Version:" >> /var/log/userdata.log
/opt/maven/bin/mvn -v >> /var/log/userdata.log

echo "Jenkins Status:" >> /var/log/userdata.log
systemctl status jenkins >> /var/log/userdata.log 2>&1




# Install dependencies
yum install ruby wget -y

cd /home/ec2-user
wget https://aws-codedeploy-ap-southeast-1.s3.amazonaws.com/latest/install

# Make it executable
chmod +x ./install

# Run the installer
sudo ./install auto

# Start the agent
sudo systemctl start codedeploy-agent

# Enable agent to start at boot
sudo systemctl enable codedeploy-agent

# Check status
sudo systemctl status codedeploy-agent
