pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' //so that kanat fffthey can be downloaded later
            }
        }  
       stage('Unit Tests - JUnit and Jacoco') {
      steps {
        sh "mvn test"
      }
      post {
        always {
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
        }
      }
    }
     stage('Mutation Tests - PIT') {
      steps {
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
      }
      post {
        always {
          pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
        }
      }
    
    stage('SonarQube - SAST') {
            steps {
              sh "mvn sonar:sonar -Dsonar.projectKey=numeric-aplication -Dsonar.host.url=http://192.168.0.21:9000 -Dsonar.login=c5319987449780570f582877d25526a557d979d3"
            }
        }  
    }
    stage('Docker Build and Push') {
      steps {
        withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
          sh 'printenv'
          sh 'docker build -t k1235/numeric-app:""$GIT_COMMIT"" .'
          sh 'docker push k1235/numeric-app:""$GIT_COMMIT""'
        }
      }
    }
    stage('Kubernetes Deployment - DEV') {
      steps {
        withKubeConfig([credentialsId: 'kubeconfig', serverUrl: 'https://192.168.0.20:6443']) {
          sh "sed -i 's#replace#k1235/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
          sh 'curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.20.5/bin/linux/amd64/kubectl"'  
          sh 'chmod u+x ./kubectl'  
          sh "./kubectl apply -f k8s_deployment_service.yaml"
        }
      }
    }
    
  }
  }

