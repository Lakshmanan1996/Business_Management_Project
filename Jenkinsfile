/* =========================================================
   BUSINESS MANAGEMENT PROJECT - COMPLETE DEVSECOPS PIPELINE
   TOOLS USED:
   - GitHub
   - Maven
   - SonarQube
   - OWASP Dependency Check
   - Docker
   - Trivy
   - DockerHub
========================================================= */

pipeline {

    agent none

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    environment {

        GIT_REPO       = "https://github.com/Lakshmanan1996/Business_Management_Project.git"

        APP_NAME       = "business-management-app"

        DOCKERHUB_USER = "lakshvar96"

        IMAGE_NAME     = "${DOCKERHUB_USER}/${APP_NAME}"

        SONAR_PROJECT  = "bmp"
       
       JAVA_HOME = "/usr/lib/jvm/java-21-openjdk-amd64"
       
       PATH = "${JAVA_HOME}/bin:${env.PATH}"
    }

    stages {

        /* =========================================================
           CHECKOUT SOURCE CODE
        ========================================================= */
        stage('Checkout Code') {

            agent { label 'workernode1' }

            steps {

                echo "Checking out source code..."

                git branch: 'master',
                    url: "${GIT_REPO}"

                stash includes: '**/*', name: 'source-code'
            }
        }

      /* =========================================================
         MAVEN BUILD
      ========================================================= */
       stage('Maven Build') {
          
          agent { label 'workernode2' }

          tools {
                maven 'maven'
            }
          
          steps {

             echo "Starting Maven build..."

             unstash 'source-code'
             
             sh '''
             chmod +x mvnw
             
             ./mvnw clean package -DskipTests
             '''
          
          }
       }

        /* =========================================================
           SONARQUBE ANALYSIS
        ========================================================= */
        stage('SonarQube Analysis') {

            agent { label 'workernode2' }

            steps {

                echo "Running SonarQube analysis..."

                unstash 'source-code'

                withSonarQubeEnv('sonarqube') {

                    sh """
                    ./mvnw sonar:sonar \
                    -Dsonar.projectKey=${SONAR_PROJECT} \
                    -Dsonar.projectName=${SONAR_PROJECT}
                    """
                }
            }
        }

        /* =========================================================
           OWASP DEPENDENCY CHECK
        ========================================================= */
        stage('OWASP Dependency Check') {

            agent { label 'workernode2' }

            steps {

                echo "Running OWASP Dependency Check..."

                unstash 'source-code'

                dependencyCheck additionalArguments: '''
                    --scan .
                    --format ALL
                ''',
                odcInstallation: 'OWASP-Dependency-Check'

                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        /* =========================================================
           SONARQUBE QUALITY GATE
        ========================================================= */
        stage('Quality Gate') {

            agent { label 'workernode2' }

            steps {

                timeout(time: 2, unit: 'MINUTES') {

                    waitForQualityGate abortPipeline: true
                }
            }
        }

        /* =========================================================
           DOCKER BUILD
        ========================================================= */
        stage('Docker Build') {

            agent { label 'workernode3' }

            steps {

                echo "Building Docker image..."

                unstash 'source-code'

                sh """
                docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${IMAGE_NAME}:latest
                """
            }
        }

        /* =========================================================
           TRIVY IMAGE SCAN
        ========================================================= */
        stage('Trivy Scan') {

            agent { label 'workernode3' }

            steps {

                echo "Running Trivy image scan..."

                sh """
                trivy image \
                --exit-code 0 \
                --severity HIGH,CRITICAL \
                ${IMAGE_NAME}:${BUILD_NUMBER}
                """
            }
        }

        /* =========================================================
           PUSH IMAGE TO DOCKERHUB
        ========================================================= */
        stage('Push Docker Image') {

            agent { label 'workernode3' }

            steps {

                echo "Pushing image to DockerHub..."

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {

                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    '''

                    sh """
                    docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${IMAGE_NAME}:latest
                    """
                }
            }
        }

        /* =========================================================
           CLEANUP
        ========================================================= */
        stage('Cleanup') {

            agent { label 'workernode3' }

            steps {

                echo "Cleaning local Docker images..."

                sh """
                docker rmi ${IMAGE_NAME}:${BUILD_NUMBER} || true
                docker rmi ${IMAGE_NAME}:latest || true
                """
            }
        }
    }

    /* =========================================================
       POST BUILD ACTIONS
    ========================================================= */
    post {

        success {

            echo '✅ DevSecOps Pipeline completed successfully!'
        }

        failure {

            echo '❌ DevSecOps Pipeline failed!'
        }

        always {

            cleanWs()
        }
    }
}
