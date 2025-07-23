pipeline {
    agent any

    environment {
        AWS_REGION = "ap-southeast-1"
        CODEARTIFACT_DOMAIN = "mydomain"
        CODEARTIFACT_REPO = "myrepository"
        CODEARTIFACT_URL = "https://mydomain-408803358823.d.codeartifact.ap-southeast-1.amazonaws.com/maven/myrepository/"
        S3_BUCKET = "SpringAppBundle122121212121"
        APPLICATION_NAME = "springboot-app"
        DEPLOYMENT_GROUP = "springboot-group"
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/KunnChan/codedeploydemo.git'
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
