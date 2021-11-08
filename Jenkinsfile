pipeline {
    agent any

    stages {
        stage('Clean') {
            steps {
                echo 'Cleaning...'
                sh 'make clean'
            }
        }
        stage('Build') {
            steps {
                echo 'Building...'
                sh 'make'
                archiveArtifacts artifacts: '**/release/*', fingerprint: true
                archiveArtifacts artifacts: '**/release/baseq2/*', fingerprint: true
            }
        }
        stage('Test') {
            steps {
                echo 'Testing...'
            }
        }
        stage('Package') {
            steps {
                echo "Packaging..."
            }
        }
    }
}
