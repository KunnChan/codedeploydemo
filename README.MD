# Deploy Spring Boot app EC2 using CodeDeploy

GitHub → Jenkins → Build Spring Boot → Upload .jar to CodeArtifact → Deploy to EC2 via CodeDeploy

1. Generate GitHub personal Authtoken
2. Setup Up GitHub webhook with Jenkins

3. Create CodeArtifact Domain

```sh
   aws codeartifact create-domain --domain mydomain
```

4. Create Repository

```sh
aws codeartifact create-repository \
  --domain mydomain \
  --repository myrepository \
  --description "Spring Boot artifacts"
```

5. Get Login Token

```sh
export CODEARTIFACT_AUTH_TOKEN=$(aws codeartifact get-authorization-token \
  --domain mydomain \
  --query authorizationToken \
  --output text)
```

6. Configure Maven Settings (on Jenkins EC2)

mkdir -p ~/.m2
~/.m2/settings.xml

```xml
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
```

7. Setup AWS CodeDeploy

   - Create an IAM Role for EC2
     - Name: CodeDeployEC2Role
     - Attach managed policy: _AmazonEC2RoleforAWSCodeDeploy_
       This role is attached to EC2 instances so CodeDeploy can access them.

```sh
aws iam create-role \
  --role-name CodeDeployEC2Role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy \
  --role-name CodeDeployEC2Role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy

aws iam attach-role-policy \
  --role-name CodeDeployEC2Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

```

- Create an IAM Role for CodeDeploy
  - Name: CodeDeployServiceRole
  - Attach policy: _AWSCodeDeployRole_
    This role is assumed by the CodeDeploy service to manage the deployment.

```sh
aws iam create-role \
  --role-name CodeDeployServiceRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy \
  --role-name CodeDeployServiceRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole

```

8. Create a Target Group (for ALB)

```sh
aws elbv2 create-target-group \
  --name springboot-target-group \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-xxxxxxxx \
  --target-type instance

```

9. Create an Application Load Balancer (ALB)

```sh
aws elbv2 create-load-balancer \
  --name springboot-alb \
  --subnets subnet-aaaaaaa subnet-bbbbbbb \
  --security-groups sg-xxxxxxxx \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4

```

10. Create Listener

```sh
aws elbv2 create-listener \
  --load-balancer-arn <alb-arn> \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=<target-group-arn>

```

11. Encypt userdata.sh to base64 String

```sh
base64 userdata.sh > encoded.txt

```

12. Create Auto Scaling Launch Template

```sh
aws ec2 create-launch-template \
  --launch-template-name springboot-template \
  --version-description "Spring Boot App Launch Template" \
  --launch-template-data '{
      "ImageId":"ami-xxxxxxxx",
      "InstanceType":"t3.micro",
      "KeyName":"your-key",
      "SecurityGroupIds":["sg-xxxxxxxx"],
      "UserData":"<base64-encoded-user-data-script>"
  }'

```

13. Encypt userdata.sh to base64 String

```sh
base64 userdata.sh > encoded.txt

```

14. Create Auto Scaling Group

```sh
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name springboot-asg \
  --launch-template LaunchTemplateName=springboot-template,Version=1 \
  --min-size 1 \
  --max-size 2 \
  --desired-capacity 1 \
  --vpc-zone-identifier "subnet-aaaaaaa,subnet-bbbbbbb" \
  --target-group-arns arn:aws:elasticloadbalancing:<region>:<acct-id>:targetgroup/springboot-target-group/xxxx

```

15. Create Application + Deployment Group (Blue/Green)

```bash

aws deploy create-application \
  --application-name springbootapp \
  --compute-platform Server


aws deploy create-deployment-group \
  --application-name springbootapp \
  --deployment-group-name springboot-dg-bluegreen \
  --deployment-style deploymentType=BLUE_GREEN,deploymentOption=WITH_TRAFFIC_CONTROL \
  --service-role-arn arn:aws:iam::<account-id>:role/CodeDeployServiceRole \
  --blue-green-deployment-configuration '{
      "terminateBlueInstancesOnDeploymentSuccess": {
        "action": "TERMINATE",
        "terminationWaitTimeInMinutes": 5
      },
      "deploymentReadyOption": {
        "actionOnTimeout": "CONTINUE_DEPLOYMENT",
        "waitTimeInMinutes": 0
      },
      "greenFleetProvisioningOption": {
        "action": "DISCOVER_EXISTING"
      }
  }' \
  --auto-scaling-groups springboot-asg \
  --load-balancer-info 'targetGroupPairInfoList=[
      {
        "targetGroups": [
          {"name": "springboot-target-group"}
        ],
        "prodTrafficRoute": {
          "listenerArns": ["arn:aws:elasticloadbalancing:<region>:<acct-id>:listener/app/springboot-alb/xxx/yyy"]
        }
      }
  ]'

```

9. Prepare appspec.yml (place at the root of your project)

```sh
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
```

10. Prepare scripts/start.sh

```sh
#!/bin/bash
pkill -f 'java -jar' || true
nohup java -jar /home/ec2-user/app/app.jar > /home/ec2-user/app/app.log 2>&1 &

```
