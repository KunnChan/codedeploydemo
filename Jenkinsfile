pipeline {
    agent any

    environment {
        AWS_REGION = "ap-southeast-1"
        CODEARTIFACT_DOMAIN = "mydomain"
        CODEARTIFACT_REPO = "myrepository"
        CODEARTIFACT_URL = "https://mydomain-408803358823.d.codeartifact.ap-southeast-1.amazonaws.com/maven/myrepository/"
        S3_BUCKET = "springappbundle122121212121"
        APPLICATION_NAME = "springbootapp"
        DEPLOYMENT_GROUP = "springboot-dg-bluegreen"
        DEPLOYMENT_ZIP = "deployment.zip"
        PATH = "/opt/maven/bin:${env.PATH}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Push to CodeArtifact') {
            steps {
                sh '''
                    CODEARTIFACT_AUTH_TOKEN=$(aws codeartifact get-authorization-token \
                    --domain mydomain \
                    --domain-owner 408803358823 \
                    --region ap-southeast-1 \
                    --query authorizationToken \
                    --output text)

                    export CODEARTIFACT_AUTH_TOKEN

                    mvn --settings /home/ec2-user/.m2/settings.xml deploy -DaltDeploymentRepository=mydomain-myrepository::https://mydomain-408803358823.d.codeartifact.ap-southeast-1.amazonaws.com/maven/myrepository/
                '''
            }
        }


        stage('Prepare Deployment Bundle') {
            steps {
                sh """
                    mkdir -p target/deploy
                    cp target/*.jar target/deploy/app.jar
                    cp appspec.yml target/deploy/
                    mkdir -p target/deploy/scripts
                    cp scripts/start.sh target/deploy/scripts/
                    chmod +x target/deploy/scripts/start.sh
                    cd target/deploy && zip -r ../../${DEPLOYMENT_ZIP} *
                """
            }
        }

        stage('Upload to S3') {
            steps {
                sh """
                    aws s3 cp ${DEPLOYMENT_ZIP} s3://${S3_BUCKET}/${DEPLOYMENT_ZIP} --region ${AWS_REGION}
                """
            }
        }

        stage('Trigger CodeDeploy') {
            steps {
                sh """
                    aws deploy create-deployment \
                        --application-name ${APPLICATION_NAME} \
                        --deployment-group-name ${DEPLOYMENT_GROUP} \
                        --s3-location bucket=${S3_BUCKET},key=${DEPLOYMENT_ZIP},bundleType=zip \
                        --region ${AWS_REGION}
                """
            }
        }
    }
}
