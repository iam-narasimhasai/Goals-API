pipeline {
    agent any
    tools {
        nodejs 'nodejs-18-20-6'
    }
    environment {
        MONGO_URL = "mongodb+srv://sai:secret32412@cluster0.awxhn.mongodb.net/course-goals?retryWrites=true&w=majority"
        GIT_TOKEN = credentials('githubtoken')
        SONAR_SCANNER_HOME = tool 'sonarqube-scanner-7'
    }

    options {
        disableResume()
        disableConcurrentBuilds(abortPrevious: true)
    }

    stages {

        stage('Installing Dependencies') {
            options { timestamps() }
            steps {
                sh ' npm install '
            }
        }

        
        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--scan / --out owasp-report --disableYarnAudit --prettyPrint --format ALL', 
                                nvdCredentialsId: 'NVD-API-KEY', 
                                odcInstallation: 'OWASP-DepCheck-12'

                // Uncomment to publish results and fail the build for critical vulnerabilities
                // dependencyCheckPublisher failedTotalCritical: 1, pattern: 'backend/owasp-report/dependency-check-report.xml', stopBuild: true
            }
        }

        stage('Run Unit Testing') {
            options { retry(3) }
            steps {
                sh 'npm run test'
            }
        }

        stage('Code Coverage') {
            steps {
                catchError(message: 'Oops! it will be fixed in future', stageResult: 'UNSTABLE') {
                    sh 'npm run coverage'

                }
            }
        }

        stage('SAST - SonarQube') {
            steps {
                timeout(time: 60, unit: 'SECONDS') {
                    withSonarQubeEnv('sonar-qube-server') {
                        sh '''
                            echo $SONAR_SCANNER_HOME

                            $SONAR_SCANNER_HOME/bin/sonar-scanner \
                                -Dsonar.projectKey=GoalsApp \
                                -Dsonar.sources=app.js \
                                -Dsonar.javascript.lcov.reportPaths=./coverage/lcov.info
                        '''
                    }
                    waitForQualityGate(abortPipeline: true)
                }
            }
        }
        

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t narasimhasai95/goalsapi:${GIT_COMMIT} .
                '''
            }
        }

        stage('Trivy Docker Image Scan') {
            steps {
                sh '''
                    mkdir -p trivy-report
                    trivy image --severity CRITICAL,HIGH,MEDIUM --format template --template "@/var/lib/jenkins/html.tpl" -o trivy-report/vulnerability-report.html narasimhasai95/goalsapi:${GIT_COMMIT}
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                withDockerRegistry(credentialsId: 'docker-creds', url: "") {
                    sh 'docker push narasimhasai95/goalsapi:${GIT_COMMIT}'
                }
            }
        }
/*
        stage('Deploy to Kubernetes') {
            steps {
                sh 'git clone -b main https://github.com/iam-narasimhasai/GoalsApp_Manifest'
                dir("GoalsApp_Manifest") {
                    sh '''
                        git checkout main
                        sed -i "s#narasimhasai95.*#narasimhasai95/goalsapi:${GIT_COMMIT}#g" deploy-backend.yaml

                        cat deploy-backend.yaml
                        
                        git config --global user.email "narasimhasai.nimmagadda@gmail.com"
                        git remote set-url origin https://$GIT_TOKEN@github.com/iam-narasimhasai/GoalsApp_Manifest
                        git add .
                        git commit -am "Updated the docker image"
                        git push -u origin main
                    '''
                }
            }
        }

*/

    }

    post {
        always {
            script {
                if (fileExists('GoalsApp_Manifest')) {
                    sh 'rm -rf GoalsApp_Manifest'
                }
            }
            
            publishHTML([
                allowMissing: true, 
                alwaysLinkToLastBuild: true, 
                keepAll: true, 
                reportDir: 'backend/owasp-report', 
                reportFiles: 'dependency-check-jenkins.html', 
                reportName: 'Dependency HTML Report', 
                useWrapperFileDirectly: true
            ])

            junit allowEmptyResults: true, testResults: 'backend/test-results.xml'

            publishHTML([
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'backend/coverage/lcov-report',
                reportFiles: 'index.html',
                reportName: 'Code Coverage HTML Report',
                useWrapperFileDirectly: true
            ])

            publishHTML([
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'trivy-report',
                reportFiles: 'vulnerability-report.html',
                reportName: 'Trivy Vulnerability Report',
                useWrapperFileDirectly: true
            ])

        }
    }
    
}