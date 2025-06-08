pipeline {
  agent any

  environment {
    VSPHERE_USER     = credentials('vsphere-user-id')
    VSPHERE_PASSWORD = credentials('vsphere-password-id')
    VSPHERE_SERVER   = '192.168.100.10'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Init') {
      steps {
        bat 'terraform init'
      }
    }

    stage('Terraform Plan') {
      steps {
        bat '''
          terraform plan -out=planfile ^
            -var "vsphere_user=%VSPHERE_USER%" ^
            -var "vsphere_password=%VSPHERE_PASSWORD%" ^
            -var "vsphere_server=%VSPHERE_SERVER%"
        '''
        archiveArtifacts artifacts: 'planfile'
      }
    }

    stage('Approval') {
      when {
        branch 'main'
      }
      steps {
        input message: 'Approve Terraform Apply?'
      }
    }

    stage('Terraform Apply') {
      steps {
        bat 'terraform apply -auto-approve planfile'
      }
    }
  }

  post {
    always {
      cleanWs()
    }
  }
}
