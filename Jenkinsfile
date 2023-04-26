
String determineRepoName() {
    return scm.getUserRemoteConfigs()[0].getUrl().tokenize('/').last().split("\\.")[0]
}

pipeline {
    agent any
    environment {
        APP_NAME = determineRepoName()
        SHORT_COMMIT = GIT_COMMIT.take(7)
        HTTP_PROXY = "http://10.13.52.31:1107"
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
                expression { binding.hasVariable('SECURITY_SCAN') }
                expression { SECURITY_SCAN == true}
            }
            environment {
                VUL_TYPE ="os,library"
            }
            steps {
                // Create trivy ignore policy file

                script {
                    IGNORE_POLICY_REGO_FILE = sh(returnStdout: true, script: 'mktemp').trim()
                    sh """
                    cat > ${IGNORE_POLICY_REGO_FILE} <<EOF
                    package trivy
                    import data.lib.trivy
                    default ignore = false
                    ignore_pkgs := {"setuptools"}
                    ignore {
                        input.PkgName == ignore_pkgs[_]
                    }
                    """
                }
                script {
                    def PROXY_SET_VAR = ""
                    if (env.HTTP_PROXY?.trim()){
                        PROXY_SET_VAR = " --env HTTP_PROXY=\"${HTTP_PROXY}\" --env HTTPS_PROXY=\"${HTTP_PROXY}\""
                    }

                    try {
                        withCredentials([string(credentialsId: 'GITHUB_TOKEN', variable: 'GITHUB_TOKEN')]) {
                            sh """
                                docker run --rm --env GITHUB_TOKEN=${env.GITHUB_TOKEN} \
                                    -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/trivy:/tmp/trivy \
                                    -v ${IGNORE_POLICY_REGO_FILE}:${IGNORE_POLICY_REGO_FILE} \
                                    ${PROXY_SET_VAR} \
                                    aquasec/trivy:latest --cache-dir /tmp/trivy/ image \
                                    --ignore-unfixed --exit-code 1 --scanners vuln \
                                    --vuln-type ${VUL_TYPE} \
                                    --ignore-policy ${IGNORE_POLICY_REGO_FILE} \
                                    --severity HIGH,CRITICAL ${APP_NAME}:${BRANCH_NAME}-${SHORT_COMMIT}
                            """
                        }
                    } catch (Exception e) {
                        if (e.getMessage().contains("Could not find credentials entry with ID 'GITHUB_TOKEN'")) {
                            echo "Warning: ${e.getMessage()}. It is needed to pass trivy db updating ratelimit"
                            sh """
                                docker run --rm \
                                    -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/trivy:/tmp/trivy \
                                    -v ${IGNORE_POLICY_REGO_FILE}:${IGNORE_POLICY_REGO_FILE} \
                                    ${PROXY_SET_VAR} \
                                    aquasec/trivy:latest --cache-dir /tmp/trivy/ image \
                                    --ignore-unfixed --exit-code 1 --scanners vuln \
                                    --vuln-type ${VUL_TYPE} \
                                    --ignore-policy ${IGNORE_POLICY_REGO_FILE} \
                                    --severity HIGH,CRITICAL ${APP_NAME}:${BRANCH_NAME}-${SHORT_COMMIT}
                            """
                        } else {
                            throw e
                        }
                    }
                    sh "rm ${IGNORE_POLICY_REGO_FILE}"
                }
            }
        }
    }
}