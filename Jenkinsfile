
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
    }

    post {
        success {
            echo 'SUCCESS: Build, tests, and Docker image creation completed!'
        }
        failure {
            echo 'FAILED: Check Console Output for the error.'
        }
    }
}
