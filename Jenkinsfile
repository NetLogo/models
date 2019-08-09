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
        sh "sbt update"
        sh "sbt test:compile"
      }
    }

    stage('Test') {
      steps {
        sh "sbt test"
        sh "sbt test -Dorg.nlogo.is3d=true"
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
