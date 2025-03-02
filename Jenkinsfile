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
                sh 'npm install'
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                sh 'mkdir -p owasp-report'
                dependencyCheck additionalArguments: '--scan . --out ./owasp-report --disableYarnAudit --prettyPrint --format ALL',
                                nvdCredentialsId: 'NVD-API-KEY',
                                odcInstallation: 'OWASP-DepCheck-12'
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
                }
                waitForQualityGate(abortPipeline: true)
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t narasimhasai95/goalsapi:${GIT_COMMIT} .'
            }
        }

        stage('Trivy Docker Image Scan') {
            steps {
                sh '''
                    mkdir -p trivy-report
                    trivy image --severity CRITICAL,HIGH,MEDIUM --format template \
                        --template "@/var/lib/jenkins/html.tpl" -o trivy-report/vulnerability-report.html \
                        narasimhasai95/goalsapi:${GIT_COMMIT}
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                withDockerRegistry(credentialsId: 'dockerhub-creds', url: "") {
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

        stage('Upload - AWS S3') {
            steps {
                withAWS(credentials: 'aws-creds', region: 'us-east-1') {  
                    sh '''
                        ls -ltr
                        mkdir reports-${BUILD_ID}
                        cp -rf coverage/ reports-${BUILD_ID}/
                        cp -rf owasp-report/ reports-${BUILD_ID}/
                        cp -rf trivy-report/ reports-${BUILD_ID}/
                        cp test-results.xml reports-${BUILD_ID}/
                        ls -ltr reports-${BUILD_ID}/
                    '''

                    s3Upload(
                        file: "reports-${BUILD_ID}",
                        bucket: 'goalsapi-jenkins-reports-bucket',
                        path: "jenkins-${BUILD_ID}/"
                    )
                }
            }
        }
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
                reportDir: 'owasp-report', 
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
