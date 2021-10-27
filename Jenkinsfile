pipeline {
    agent {
        label 'master'
    }

    options {
        disableConcurrentBuilds()
        skipDefaultCheckout()
    }

    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                commonCheckout()
            }
        }

        stage('Create Release') {
            when {
                anyOf {
                    branch 'master'
                }
            }
            steps {
                gradleCreateRelease()
            }
        }

        stage('Check Container Build') {
            when {
                not {
                    anyOf {
                        branch 'master'
                    }
                }
            }
            steps {
                checkDockerBuild()
            }
        }

        stage('Build Container') {
            when {
                anyOf {
                    branch 'master'
                }
            }
            steps {
                buildAndPushContainer()
            }
        }

        stage('Publish Release') {
            when {
                anyOf {
                    branch 'master'
                }
            }
            steps {
                finishRelease()
            }
        }
    }
}