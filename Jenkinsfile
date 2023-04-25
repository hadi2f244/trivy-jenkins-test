String determineRepoName() {
    return scm.getUserRemoteConfigs()[0].getUrl().tokenize('/').last().split("\\.")[0]
}

def getPropOrDefault( Closure c, def defaultVal ) {
    try {
        return c()
    }
    catch( groovy.lang.MissingPropertyException e ) {
        return defaultVal
    }
}

pipeline {
    agent any
    environment {
        APP_NAME = determineRepoName()
        SHORT_COMMIT = GIT_COMMIT.take(7)
    }
    stages {
        stage('Build Image') {
            steps {
                script {
                    dockerImage = docker.build("${APP_NAME}:${BRANCH_NAME}-${SHORT_COMMIT}", "--pull --build-arg BRANCH=${BRANCH_NAME} --build-arg COMMIT=${GIT_COMMIT} .")
                }
            }
        }
        stage('Load Environment Variables') {
            steps {
                script {
                    load "jenkins/env.groovy"
                }
            }
        }
        stage("Security Scan") {
            when {
                expression { SECURITY_SCAN == true }
            }
            steps {
                script {
                    try {
                        withCredentials([string(credentialsId: 'GITHUB_TOKEN', variable: 'GITHUB_TOKEN')]) {
                            sh """
                                docker run --env GITHUB_TOKEN=${env.GITHUB_TOKEN} -v /tmp/trivy:/tmp/trivy aquasec/trivy:latest \
                                    --cache-dir /tmp/trivy/ image --no-progress  --ignore-unfixed \
                                    --exit-code 1 --scanners vuln --severity HIGH,CRITICAL ${APP_NAME}:${BRANCH_NAME}-${SHORT_COMMIT}
                            """
                        }
                    } catch (Exception e) {
                        echo "Error: ${e.getMessage()}"
                        sh """
                            docker run -v /tmp/trivy:/tmp/trivy aquasec/trivy:latest \
                                --cache-dir /tmp/trivy/ image --no-progress  --ignore-unfixed \
                                --exit-code 1 --scanners vuln --severity HIGH,CRITICAL ${APP_NAME}:${BRANCH_NAME}-${SHORT_COMMIT}
                        """
                    }

                }
            }
        }
    }
}