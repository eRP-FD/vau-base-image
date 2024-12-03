pipeline {
    agent {
        label 'master'
    }

    options {
        disableConcurrentBuilds()
        skipDefaultCheckout()
    }

    tools {
        jdk 'jdk_17'
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
                    branch 'release/*'
                }
            }
            steps {
                gradleCreateVersionRelease()
            }
        }

        stage('SBOM and Sonar') {
            steps {
                 withVault(
                    [[path: "secret/eRp/dependencytrack", secretValues: [[vaultKey: 'dependencytrack_apikey', envVar: 'DEPENDENCYTRACK_APIKEY']]],
                        [path: "secret/eRp/dependencytrack", secretValues: [[vaultKey: 'frontend_url', envVar: 'DEPENDENCYTRACK_FRONTEND_URL']]],
                        [path: "secret/eRp/dependencytrack", secretValues: [[vaultKey: 'serverhostname', envVar: 'DEPENDENCYTRACK_SERVER_HOSTNAME']]],
                        [path: "secret/eRp/sonarqube", secretValues: [[vaultKey: 'sonarqubetoken', envVar: 'SONARQUBE_TOKEN']]],
                        [path: "secret/eRp/sonarqube", secretValues: [[vaultKey: 'sonarqubeurl', envVar: 'SONARQUBE_URL']]]
                        ]
                    
                 ) {
                    staticAnalysis()
                    dependencyTrack()
                }
            }
        }

        stage('SBOM Generation') {
            steps {
                script {
                    sbomSyft()
                }
            }
        }

        stage('Check Container Build') {
            when {
                not {
                    anyOf {
                        branch 'master'
                        branch 'release/*'
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
                    branch 'release/*'
                }
            }
            steps {
                buildAndPushContainer(DOCKER_OPTS: '--no-cache')
            }
        }

        stage('Publish Release') {
            when {
                anyOf {
                    branch 'master'
                    branch 'release/*'
                }
            }
            steps {
                finishRelease()
            }
        }
    }
    post {
        success {
            script {
                if (env.BRANCH_NAME == 'master' || env.BRANCH_NAME == 'main' || env.BRANCH_NAME.startsWith("release/")) {
                    build wait: false, job: '/eRp/Integration/eRp_Scan_Image_Vulnerabilities',
                        parameters: [[$class: 'StringParameterValue', name: 'service', value: 'vau-base-image'],
                                     [$class: 'StringParameterValue', name: 'version', value: currentBuild.displayName]]
                }
            }
        }
    }
}
