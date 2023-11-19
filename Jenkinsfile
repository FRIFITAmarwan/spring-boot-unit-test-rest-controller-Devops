def ENV_NAME = getEnvName(env.BRANCH_NAME)
def CONTAINER_NAME = "calc-" +ENV_NAME
def CONTAINER_TAG = getTag(env.BUILD_NUMBER, env.BRANCH_NAME)
def HTTP_PORT = getHTTPPort(env.BRANCH_NAME)
def EMAIL_RECIPIENTS = "frifitamarwan1@gmail.com"


node {
    try {
        stage('Initialize') {
            def dockerHome = tool 'dockerlatest2'
            def mavenHome = tool 'mavenlatest2'
            env.PATH = "${dockerHome}/bin:${mavenHome}/bin:${env.PATH}"
        }

        stage('Checkout') {
            checkout scm
        }

        stage('Build with test') {

            sh "mvn clean install -DfailIfNoTests=false"
        }

        stage('Sonarqube Analysis') {
            withSonarQubeEnv('sonarServer') {
                sh " mvn sonar:sonar -Dintegration-tests.skip=true -Dmaven.test.failure.ignore=true"
            }
            timeout(time: 1, unit: 'MINUTES') {
                def qg = waitForQualityGate() // Reuse taskId previously collected by withSonarQubeEnv
                if (qg.status != 'OK') {
                    error "Pipeline aborted due to quality gate failure: ${qg.status}"
                }
            }
        }

        stage("Image Prune") {
            imagePrune(CONTAINER_NAME)
        }

        stage('Image Build') {
            imageBuild(CONTAINER_NAME, CONTAINER_TAG)
        }

        stage('Push to Docker Registry') {
            withCredentials([usernamePassword(credentialsId: 'dockerhubcredentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                pushToImage(CONTAINER_NAME, CONTAINER_TAG, USERNAME, PASSWORD)
            }
        }

        stage('Run App') {
            withCredentials([usernamePassword(credentialsId: 'dockerhubcredentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                runApp(CONTAINER_NAME, CONTAINER_TAG, USERNAME, HTTP_PORT, ENV_NAME)

            }
        }

    } finally {
        deleteDir()
        sendEmail(EMAIL_RECIPIENTS);
    }

}

def imagePrune(containerName) {
    try {
        sh "docker image prune -f"
        sh "docker stop $containerName"
    } catch (ignored) {
    }
}

def imageBuild(containerName, tag) {
    sh "docker build -t $containerName:$tag  -t $containerName --pull --no-cache ."
    echo "Image build complete"
}

def pushToImage(containerName, tag, dockerUser, dockerPassword) {
    sh "docker login -u $dockerUser -p $dockerPassword"
    sh "docker tag $containerName:$tag $dockerUser/$containerName:$tag"
    sh "docker push $dockerUser/$containerName:$tag"
    echo "Image push complete"
}

def runApp(containerName, tag, dockerHubUser, httpPort, envName) {
    sh "docker pull $dockerHubUser/$containerName"
    sh "docker run --rm --env SPRING_ACTIVE_PROFILES=$envName -d -p $httpPort:$httpPort --name $containerName $dockerHubUser/$containerName:$tag"
    echo "Application started on port: ${httpPort} (http)"
}

def sendEmail(recipients) {
    mail(
            to: recipients,
            subject: "Build ${env.BUILD_NUMBER} - ${currentBuild.currentResult} - (${currentBuild.fullDisplayName})",
            body: "Check console output at: ${env.BUILD_URL}/console" + "\n")
}

String getEnvName(String branchName) {
    if (branchName == 'master') {
        return 'prod'
    }
    return (branchName == 'preprod') ? 'uat' : 'dev'
}

String getHTTPPort(String branchName) {
    if (branchName == 'master') {
        return '8696'
    }
    return (branchName == 'preprod') ? '8797' : '8595'
}

String getTag(String buildNumber, String branchName) {
    if (branchName == 'master') {
        return buildNumber + '-unstable'
    }
    return buildNumber + '-stable'
}