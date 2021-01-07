#!/usr/bin/env groovy

def buildNumber = BUILD_NUMBER as int
if (buildNumber > 1) milestone(buildNumber - 1)
milestone(buildNumber)

pipeline {

  agent any

  stages {

    stage('Start') {
      steps {
        library 'netlogo-shared'
        sendNotifications('NetLogo/models', 'STARTED')
      }
    }

    stage('Build') {
      steps {
        sh "./sbt.sh update"
        sh "./sbt.sh test:compile"
      }
    }

    stage('Test') {
      steps {
        sh "./sbt.sh -Dorg.nlogo.is3d=true test"
        sh "./sbt.sh test"
        junit 'target/test-reports/*.xml'
      }
    }

  }

  post {

    failure {
      library 'netlogo-shared'
      sendNotifications('NetLogo/models', 'FAILURE')
    }

    success {
      library 'netlogo-shared'
      sendNotifications('NetLogo/models', 'SUCCESS')
    }

    unstable {
      library 'netlogo-shared'
      sendNotifications('NetLogo/models', 'UNSTABLE')
    }

  }
}
