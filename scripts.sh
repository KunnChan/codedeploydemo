#1. Create CodeArtifact Domain
aws codeartifact create-domain --domain mydomain

#2. Create Repository
aws codeartifact create-repository \
  --domain mydomain \
  --repository myrepository \
  --description "Spring Boot artifacts"

#3. Get Login Token
export CODEARTIFACT_AUTH_TOKEN=$(aws codeartifact get-authorization-token \
  --domain mydomain \
  --query authorizationToken \
  --output text)

# export CODEARTIFACT_AUTH_TOKEN=`aws codeartifact get-authorization-token --domain mydomain --domain-owner 408803358823 --region ap-southeast-1 --query authorizationToken --output text`

#4. Configure Maven Settings (on Jenkins EC2)
# ~/.m2/settings.xml


: <<'END_COMMENT'
<settings>
  <servers>
    <server>
      <id>mydomain-myrepository</id>
      <username>aws</username>
      <password>${env.CODEARTIFACT_AUTH_TOKEN}</password>
    </server>
  </servers>
  <profiles>
    <profile>
      <id>mydomain-myrepository</id>
      <activation>
        <activeByDefault>true</activeByDefault>
      </activation>
      <repositories>
        <repository>
          <id>mydomain-myrepository</id>
          <url>https://mydomain-408803358823.d.codeartifact.ap-southeast-1.amazonaws.com/maven/myrepository/</url>
        </repository>
      </repositories>
    </profile>
  </profiles>
  <mirrors>
    <mirror>
      <id>mydomain-myrepository</id>
      <name>mydomain-myrepository</name>
      <url>https://mydomain-408803358823.d.codeartifact.ap-southeast-1.amazonaws.com/maven/myrepository/</url>
      <mirrorOf>*</mirrorOf>
    </mirror>
  </mirrors>
</settings>
END_COMMENT

# Setup AWS CodeDeploy

# Create an IAM Role for EC2
#Name: CodeDeployEC2Role
#Attach managed policy: AmazonEC2Role for AWSCodeDeploy

# Create an IAM Role for CodeDeploy
#Name: CodeDeployServiceRole
#Attach policy: AWSCodeDeployRole


# Install CodeDeploy Agent on Target EC2
sudo yum install ruby
cd /home/ec2-user
wget https://bucket-name.s3.region.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent start

# Create Application + Deployment Group
aws deploy create-application --application-name springboot-app

aws deploy create-deployment-group \
  --application-name springboot-app \
  --deployment-group-name springboot-group \
  --deployment-config-name CodeDeployDefault.AllAtOnce \
  --ec2-tag-filters Key=Name,Value=YourEC2Tag,Type=KEY_AND_VALUE \
  --service-role-arn arn:aws:iam::<account-id>:role/CodeDeployServiceRole


# Prepare appspec.yml (place at the root of your project):
: <<'END_COMMENT'

version: 0.0
os: linux
files:
  - source: target/app.jar
    destination: /home/ec2-user/app
hooks:
  AfterInstall:
    - location: scripts/start.sh
      timeout: 60
      runas: ec2-user

END_COMMENT

# Prepare scripts/start.sh:

#!/bin/bash
pkill -f 'java -jar' || true
nohup java -jar /home/ec2-user/app/app.jar > /home/ec2-user/app/app.log 2>&1 &



