
pipeline {
    agent any

    environment {
        IMAGE_NAME     = 'devops-flask-app'
        RESOURCE_GROUP = 'rg-devopsflask-production'
        IMAGE_TAG      = "${env.BUILD_NUMBER}"
    }

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh '''
                    python3 -m venv .venv
                    . .venv/bin/activate
                    pip install --upgrade pip
                    pip install -r app/requirements.txt
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    . .venv/bin/activate
                    pytest tests/ -v --junitxml=test-results.xml
                '''
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: 'test-results.xml'
                }
            }
        }

        stage('Docker Build and Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DH_USER',
                        passwordVariable: 'DH_PASS'
                    )
                ]) {
                    sh '''
                        set -e
                        docker build \
                          -t "$DH_USER/$IMAGE_NAME:$IMAGE_TAG" \
                          -t "$DH_USER/$IMAGE_NAME:latest" .

                        echo "$DH_PASS" | docker login \
                          -u "$DH_USER" --password-stdin

                        docker push "$DH_USER/$IMAGE_NAME:$IMAGE_TAG"
                        docker push "$DH_USER/$IMAGE_NAME:latest"
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to Azure') {
            steps {
                withCredentials([
                    string(credentialsId: 'azure-client-id',
                           variable: 'AZ_CLIENT_ID'),
                    string(credentialsId: 'azure-client-secret',
                           variable: 'AZ_CLIENT_SECRET'),
                    string(credentialsId: 'azure-tenant-id',
                           variable: 'AZ_TENANT_ID'),
                    string(credentialsId: 'azure-subscription-id',
                           variable: 'AZ_SUB_ID')
                ]) {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'dockerhub-creds',
                            usernameVariable: 'DH_USER',
                            passwordVariable: 'DH_PASS'
                        )
                    ]) {
                        sh '''
                            set -e

                            az login \
                              --service-principal \
                              -u "$AZ_CLIENT_ID" \
                              -p "$AZ_CLIENT_SECRET" \
                              --tenant "$AZ_TENANT_ID" > /dev/null

                            az account set --subscription "$AZ_SUB_ID"

                            APP_NAME=$(az webapp list \
                              --resource-group "$RESOURCE_GROUP" \
                              --query "[0].name" -o tsv)

                            if [ -z "$APP_NAME" ] || [ "$APP_NAME" = "None" ]; then
                                echo "No Azure Web App found in $RESOURCE_GROUP"
                                exit 1
                            fi

                            echo "$APP_NAME" > .appname
                            echo "Deploying to $APP_NAME"

                            az webapp config container set \
                              --name "$APP_NAME" \
                              --resource-group "$RESOURCE_GROUP" \
                              --container-image-name "$DH_USER/$IMAGE_NAME:$IMAGE_TAG" \
                              --container-registry-url "https://index.docker.io"

                            az webapp config appsettings set \
                              --name "$APP_NAME" \
                              --resource-group "$RESOURCE_GROUP" \
                              --settings "APP_VERSION=$IMAGE_TAG"

                            az webapp restart \
                              --name "$APP_NAME" \
                              --resource-group "$RESOURCE_GROUP"

                            az logout
                        '''
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    set -e
                    APP_NAME=$(cat .appname)
                    URL="https://${APP_NAME}.azurewebsites.net/health"

                    echo "Checking $URL"

                    for i in $(seq 1 20); do
                        CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" || true)
                        echo "Attempt $i: HTTP $CODE"

                        if [ "$CODE" = "200" ]; then
                            echo "Deployment verified."
                            curl -s "$URL"
                            exit 0
                        fi

                        sleep 15
                    done

                    echo "Verification failed: app did not return HTTP 200."
                    exit 1
                '''
            }
        }
    }

    post {
        success {
            echo "SUCCESS: build #${env.BUILD_NUMBER} was tested, built and deployed."
        }
        failure {
            echo "FAILED: check Console Output for details."
        }
        always {
            sh 'docker image prune -f || true'
        }
    }
}
