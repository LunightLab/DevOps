/***********************************************************************
 * Jenkins Pipeline Script
 * -----------------------
 * Project Name: docker backup pipeline
 * Description: Docker gitlab 컨테이너를 백업하고 thinbackup으로 lotate 백업된 jenkins를 백업하는 파이프라인
 * Author: lunight
 * Date: [2024-12-DD]
 * Version: 1.0
 * Notes: -
*********************************************************************** */

pipeline {
    agent any
    // evn 파일
    environment {
        SVN_PATH = '/Users/mobile/Documents/gitlab-backup'
    }
    stages {
        // pipeline 1. docker backup
        stage('Docker backup') {
            steps {

                sh '''
                #!/bin/zsh -l
                CONTAINER_ID=$(docker ps -q)
                NOWDATE=`date '+%Y%m%d'`
                NOW=`date '+%Y-%m-%d_%H%M%S'`
                echo "Check container id $CONTAINER_ID"
                echo "Start commit docker container to image... 🎬"
                docker commit $CONTAINER_ID gitlab-img-$NOWDATE
                echo "Start save docker tar file...🎬"
                docker save -o ~/Documents/gitlab-backup/docker/docker-gitlab-ee-16.6.1-"$NOWDATE".tar gitlab-img-"$NOWDATE"
                '''
            }
        }
        // pipeline 2. 백업된 컨테이너 이미지 파일을 삭제
        stage('Delete container file') {
            steps {
                sh '''
                #!/bin/zsh -l
                NOWDATE=`date '+%Y%m%d'`
                BACKUP_CONTAINER=$(docker images -q gitlab-nh-"$NOWDATE")
                echo "Delete docker image"
                docker rmi $BACKUP_CONTAINER
                echo "Complete Docker image backup!! 😎"
                '''
            }
        }
        // pipeline 3. gitlab 백업
        // - gitlab 백업파일을 생성하고
        // - 컨테이너안에 저장된 gitlab 백업파일을 원하는 경로에 이동해서 가져오고
        // - 기존 gitlab 백업파일을 삭제
        stage('Gitlab backup') {
            steps {
            sh '''
            #!/bin/zsh -l
            CONTAINER_ID=$(docker ps -q)
            echo "START mobile gitlab backup process"
            echo "Start gitlab backup 🚀"
            docker exec -t $CONTAINER_ID gitlab-backup create
            echo "End gitlab backup 😎"
            echo "Start cp local file ~/Documents/gitlab-backup/gitlab 🚀"
            docker cp $CONTAINER_ID:/var/opt/gitlab/backups ~/Documents/gitlab-backup/gitlab
            echo "End tar file 😎"
            echo "Start remove file 🚀"
            docker exec $CONTAINER_ID sh -c 'rm -rf /var/opt/gitlab/backups/*'
            echo "Complete mobile gitlab backup process !! 😎"
            '''
            }
        }
        // pipeline 4. 파일매니저
        stage('bacup file manager') {
            steps {
                sh '''
                #!/bin/zsh -l
                echo "DELETE backup file update 🚀 "
                cd ${SVN_PATH}
                find docker/ -name '*.tar' -prune -mtime +14 -exec rm -Rf {} \\;
                find gitlab/backups/ -name '*.tar' -prune -mtime +14 -exec rm -Rf {} \\;
                find jenkins/* -type d -prune -mtime +14 -exec rm -rf {} \\;
                '''
            }
        }
        // pipeline 5. svn 업로드
        stage('SVN upload') {
            steps {
                sh '''
                #!/bin/zsh -l
                echo "START SVN backup process 🚀 "
                cd ${SVN_PATH}
                svn add * --force
                svn cleanup 
                svn commit -m "gitlab & docker backup" --username '<username>' --password '<password>'
                '''
            }
        }
    }
}