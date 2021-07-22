node {
    stage('Checkout'){
        checkout scm
    }

    docker.withRegistry("${params.DOCKER_REGISTRY_URL}", "${params.DOCKER_REGISTRY_CREDENTIALS}") {
        stage "build"
        def app = docker.build "${params.IMAGE_NAME}", "--target ${params.TARGET_STAGE} ."

        stage "publish"
        app.push 'latest'
    }
}
