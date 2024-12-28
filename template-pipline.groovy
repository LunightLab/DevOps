/***********************************************************************
 * Jenkins Pipeline Script
 * -----------------------
 * Project Name: [Your Project Name]
 * Description: This is a basic Jenkins Pipeline template for automating build, test, and deployment processes.
 * Author: lunight
 * Date: [YYYY-MM-DD]
 * Version: 1.0
 * Notes: Modify this script as needed to fit your specific project requirements.
*********************************************************************** */

pipeline {
    agent any // 파이프라인이 실행될 Jenkins 노드(여기서는 모든 노드에서 실행 가능)

    environment {
        // 환경 변수 정의 (필요에 따라 수정)
        GIT_REPO = 'https://github.com/your-repo.git' // Git 저장소 URL
        BRANCH = 'main' // 사용할 브랜치 이름
    }

    stages {
        stage('Checkout') { // 코드 체크아웃 단계
            steps {
                // Git에서 지정된 브랜치의 코드를 가져옴
                git branch: "${BRANCH}", url: "${GIT_REPO}"
            }
        }
        stage('Build') { // 빌드 단계
            steps {
                echo 'Building the application...' // 빌드 단계 시작 알림
                // 실제 빌드 명령어 추가 (예: Maven, Gradle, npm 등)
                sh 'echo "Build step executed"' // 예제 명령어
            }
        }
        stage('Test') { // 테스트 단계
            steps {
                echo 'Running tests...' // 테스트 단계 시작 알림
                // 실제 테스트 명령어 추가 (예: Unit Test, Integration Test 등)
                sh 'echo "Test step executed"' // 예제 명령어
            }
        }
        stage('Deploy') { // 배포 단계
            steps {
                echo 'Deploying the application...' // 배포 단계 시작 알림
                // 실제 배포 명령어 추가 (예: Docker push, 서버 배포 스크립트 등)
                sh 'echo "Deploy step executed"' // 예제 명령어
            }
        }
    }

    post {
        always {
            // 파이프라인이 완료되었을 때 항상 실행
            echo 'Pipeline execution completed!'
        }
        success {
            // 파이프라인이 성공했을 때 실행
            echo 'Pipeline succeeded!'
        }
        failure {
            // 파이프라인이 실패했을 때 실행
            echo 'Pipeline failed!'
        }
    }
}