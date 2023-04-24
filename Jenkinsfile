pipeline {
    agent any
    environment {
        IMAGE_NAME = 'nginx:latest'
    }
    stages {
        stage('Load Environment Variables') {
            steps {
                script {
                    load "jenkins/env.groovy"
                }
            }
        }
        stage("Security Scan") {
            when {
                expression { SKIP_SECURITY_SCAN == false }
            }
            steps {
                script {
                    sh """
                    docker run -v /tmp/trivy:/tmp/trivy aquasec/trivy:latest \
                        --cache-dir /tmp/trivy/ image --no-progress  --ignore-unfixed \
                        --exit-code 1 --scanners vuln --severity HIGH,CRITICAL ${env.IMAGE_NAME}
                    """
                }
            }
        }
    }
}