def kubernetes_config = """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: openjdk
    image: openjdk:11
    tty: true
    resources:
      limits:
        memory: "2Gi"
        cpu: "1"
      requests:
        memory: "2Gi"
        cpu: "1"
"""

pipeline {
    agent {
        kubernetes {
            label 'sprotty-server-agent-pod'
            yaml kubernetes_config
        }
    }
    options {
        buildDiscarder logRotator(numToKeepStr: '15')
    }
    
    stages {
        stage('Build sprotty-server') {
            environment {
                GRADLE_ARGS = "--no-daemon --refresh-dependencies --continue -PignoreTestFailures=true"
            }
            steps {
                container('openjdk') {
                    sh "./gradlew ${env.GRADLE_ARGS} build createLocalMavenRepo"
                }
            }
        }
    }
    
    post {
        success {
            junit '**/build/test-results/test/*.xml'
            archiveArtifacts 'build/maven-repository/**'
        }
    }
}