pipeline {
    agent any

    environment {
        AWS_REGION = "ap-southeast-1"
        CODEARTIFACT_DOMAIN = "my-domain"
        CODEARTIFACT_REPO = "my-repo"
        CODEARTIFACT_URL = "https://${CODEARTIFACT_DOMAIN}-111122223333.d.codeartifact.${AWS_REGION}.amazonaws.com/maven/${CODEARTIFACT_REPO}/"
        S3_BUCKET = "your-deployment-bucket"
        APPLICATION_NAME = "springboot-app"
        DEPLOYMENT_GROUP = "springboot-group"
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/your/repo.git'
            }
        }

        stage('Build') {
            steps {
                sh './mvnw clean package -DskipTests'
            }
        }

        stage('Push to CodeArtifact') {
            steps {
                withCredentials([string(credentialsId: 'aws-codeartifact-token', variable: 'CODEARTIFACT_AUTH_TOKEN')]) {
                    sh """
                        aws codeartifact login \
                          --tool maven \
                          --domain $CODEARTIFACT_DOMAIN \
                          --repository $CODEARTIFACT_REPO \
                          --region $AWS_REGION

                        mvn deploy -DaltDeploymentRepository=codeartifact::default::${CODEARTIFACT_URL}
                    """
                }
            }
        }

        stage('Upload to S3 for CodeDeploy') {
            steps {
                sh """
                  zip -r deployment.zip appspec.yml scripts/ target/app.jar
                  aws s3 cp deployment.zip s3://$S3_BUCKET/
                """
            }
        }

        stage('Deploy with CodeDeploy') {
            steps {
                sh """
                  aws deploy create-deployment \
                    --application-name $APPLICATION_NAME \
                    --deployment-group-name $DEPLOYMENT_GROUP \
                    --s3-location bucket=$S3_BUCKET,key=deployment.zip,bundleType=zip \
                    --region $AWS_REGION
                """
            }
        }
    }
}
