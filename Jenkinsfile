pipeline {
  agent any
  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "k1235/numeric-app:${GIT_COMMIT}"
    applicationURL = "http://192.168.0.20"
    applicationURI = "/increment/99"
  }
  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' 
            }
        }  
      stage('Unit Tests - JUnit and Jacoco') {
      steps {
        sh "mvn test"
      }
      
    }
     stage('Mutation Tests - PIT') {
      steps {
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
      }
     }
    
    stage('SonarQube - SAST') {
      steps {
        withSonarQubeEnv('SonarQube') {
          sh "mvn sonar:sonar -Dsonar.projectKey=numeric-application -Dsonar.host.url=http://192.168.0.21:9000"
        }
        timeout(time: 2, unit: 'MINUTES') {
          script {
            waitForQualityGate abortPipeline: true
          }
        }
      }
    }

     stage('Vulnerability Scan - Docker') {
      steps {
        parallel(
          "Dependency Scan": {
            sh "mvn dependency-check:check"
          },
          "Trivy Scan": {
            sh "bash trivy-docker-image-scan.sh"
          },
          "OPA Conftest": {
            sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
          }
        )
      }
    }


    stage('Docker Build and Push') {
      steps {
        withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
          sh 'printenv'
          sh 'sudo docker build -t k1235/numeric-app:""$GIT_COMMIT"" .'
          sh 'docker push k1235/numeric-app:""$GIT_COMMIT""'
        }
      }
    }
 /*   
   stage('Vulnerability Scan - Kubernetes') {
      steps {
        sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
      }
    }
    
 //   stage('Kubernetes Deployment - DEV') {
 //    steps {
 //       withKubeConfig([credentialsId: 'kubeconfig', serverUrl: 'https://192.168.0.20:6443']) {
 //         sh "sed -i 's#replace#k1235/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
 //         sh 'curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.20.5/bin/linux/amd64/kubectl"'  
 //         sh 'chmod u+x ./kubectl'  
 //         sh "./kubectl apply -f k8s_deployment_service.yaml"
 //       }
 //     }
 //   }
*/
    
   stage('Vulnerability Scan - K8s') {
      steps {
        parallel(
          "OPA Scan": {
            sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
          },
          "Kubesec Scan": {
            sh "bash kubesec-scan.sh"
          },
          "Trivy Scan": {
            sh "bash trivy-k8s-scan.sh"
          }
        )
      }
    }

   stage('K8s Deployment - Test') {
       steps {
         parallel(
           "Deployment": {
              withKubeConfig([credentialsId: 'kubeconfig', serverUrl: 'https://192.168.0.20:6443']) {
           sh "bash k8s-deployment.sh"
           }
           },
           "Rollout Status": {
             withKubeConfig([credentialsId: 'kubeconfig', serverUrl: 'https://192.168.0.20:6443']) {
               sh "bash k8s-deployment-rollout-status.sh"
             }
           }
         )
     }
}
 /* Dont work application   
    stage('Integration Tests - DEV') {
      steps {
        script {
          try {
            withKubeConfig([credentialsId: 'kubeconfig', serverUrl: 'https://192.168.0.20:6443']) {
              sh "bash integration-test.sh"
            }
          } catch (e) {
            withKubeConfig([credentialsId: 'kubeconfig', serverUrl: 'https://192.168.0.20:6443']) {
              sh "kubectl -n default rollout undo deploy ${deploymentName}"
            }
            throw e
          }
        }
      }
    }
 */ 
    stage('Prompte to PROD?') {
      steps {
        timeout(time: 2, unit: 'DAYS') {
          input 'Do you want to Approve the Deployment to Production Environment/Namespace?'
        }
      }
    }
    stage('K8S Deployment - PROD') {
      steps {
        parallel(
          "Deployment": {
            withKubeConfig([credentialsId: 'kubeconfig', serverUrl: 'https://192.168.0.20:6443']) {
              sh "sed -i 's#replace#${imageName}#g' k8s_PROD-deployment_service.yaml"
              sh "kubectl -n prod apply -f k8s_PROD-deployment_service.yaml"
            }
          },
          "Rollout Status": {
            withKubeConfig([credentialsId: 'kubeconfig', serverUrl: 'https://192.168.0.20:6443']) {
              sh "bash k8s-PROD-deployment-rollout-status.sh"
            }
          }
        )
      }
    }

    
  }
  
  post {
    always {
      junit 'target/surefire-reports/*.xml'
      jacoco execPattern: 'target/jacoco.exec'
      pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
      dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
    }
}
}
  

