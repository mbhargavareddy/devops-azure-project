
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh '''
                    python3 --version
                    python3 -m venv .venv
                    . .venv/bin/activate
                    pip install -r app/requirements.txt
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    . .venv/bin/activate
                    pytest tests/ -v
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t devops-flask-app:latest .
                    docker images
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    docker rm -f devops-flask-app || true
                    docker run -d \
                        --name devops-flask-app \
                        --restart unless-stopped \
                        -p 5000:8000 \
                        devops-flask-app:latest
                '''
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Build, tests, Docker image, and deployment completed!'
        }
        failure {
            echo 'FAILED: Check Console Output for the error.'
        }
    }
}
