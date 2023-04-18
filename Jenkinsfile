pipeline {
    agent any
    environment {
        IMAGE_NAME = 'nginx:latest'
    }
    stages {
        stage('Load Environment Variables') {
            steps {
                script {
                    load "${env.WORKSPACE}/.env"
                }
            }
        }
        stage("Security Scan") {
            when {
                not {
                    expression { return SKIP_SECURITY_SCAN }
                }
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