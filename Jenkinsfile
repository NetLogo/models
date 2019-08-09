#!/usr/bin/env groovy

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
        sh "./sbt.sh test"
        sh "./sbt.sh test -Dorg.nlogo.is3d=true"
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
