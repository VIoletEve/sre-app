pipeline {
    agent any
    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timeout(time: 20,unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    environment {
        REGISTRY='10.0.0.103'
        IMAGE_REPO='10.0.0.103/sre-demo/web'
        GITOPS_URL= 'https://github.com/VIoletEve/sre-gitops.git'
    }
    stages {
        stage('拉代码') {
            steps {
                checkout scm
            }
        }

        stage('构建镜像') {
            steps {
                script {
                    env.TAG = "build-${BUILD_NUMBER}"
                }

                sh '''
                    docker build -t ${IMAGE_REPO}:${TAG} .
                    docker run --rm --entrypoint nginx ${IMAGE_REPO}:${TAG} -t
                '''
            }
        }
        stage('推送 Harbor') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'harbor-ci',
                        usernameVariable: 'HARBOR_USER',
                        passwordVariable: 'HARBOR_PASS'
                    )
                ]) {
                    sh '''
                        echo "$HARBOR_PASS" | \
                        docker login $REGISTRY \
                        -u "$HARBOR_USER" \
                        --password-stdin

                        docker push ${IMAGE_REPO}:${TAG}
                    '''
                }
            }
        }

        stage('更新 GitOps') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'gitops-write',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )
                ]) {
                    sh '''
                        rm -rf gitops
                        git clone $GITOPS_URL gitops
                        cd gitops

                        sed -i "s|^  repository:.*| repository: ${IMAGE_REPO}|" \
                            environments/dev-values.yaml

                        sed -i "s|^  tag:.*|  tag: ${TAG}|" \
                            environments/dev-values.yaml

                        git config user.name "Jenkins CI"
                        git config user.email "jenkins@example.com"

                        git add environments/dev-values.yaml
                        git commit -m "ci: deploy dev ${TAG}"

                        git push https://${GIT_USER}:${GIT_TOKEN}@github.com/VIoletEve/sre-gitops.git main                      
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '哈基米部署成功！'
        }

        failure {
            echo '哈基米起飞失败~'
        }
    }

}


