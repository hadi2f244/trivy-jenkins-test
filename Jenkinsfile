pipeline {
    agent any
    stages {
        stage('Load Environment Variables') {
            steps {
                script {
                    def envVars = load("${env.WORKSPACE}/.env")
                    envVars.each { key, value -> env."${key}" = "${value}"}
                }
            }
        }
        stage("Security Scan") {
            steps {
                script {
                    sh 'docker run -v /tmp/trivy:/tmp/trivy aquasec/trivy:latest \
                        --cache-dir /tmp/trivy/ image --no-progress  --ignore-unfixed \
                        --exit-code 1 --scanners vuln --severity HIGH,CRITICAL python:3.9.16-bullseye'
                }
            }
        }
    }
}