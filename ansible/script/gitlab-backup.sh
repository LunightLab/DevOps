#!/bin/bash
# GitLab Docker 완전 백업 스크립트

BACKUP_DIR="$HOME/gitlab-backups"
GITLAB_CONTAINER="gitlab"
DATE=$(date +%Y%m%d_%H%M%S)
KEEP_DAYS=30

echo "🗄️ GitLab 완전 백업 시작: $DATE"

# 백업 디렉토리 생성 (홈 디렉토리 - 권한 안전)
mkdir -p $BACKUP_DIR
chmod 755 $BACKUP_DIR

echo "📋 1단계: GitLab 내장 백업 실행..."
# GitLab 애플리케이션 백업 (가장 중요!)
docker exec $GITLAB_CONTAINER gitlab-backup create BACKUP=$DATE

echo "📋 2단계: GitLab 백업 파일 추출..."
# GitLab 백업 파일을 호스트로 복사
GITLAB_BACKUP_FILE="${DATE}_gitlab_backup.tar"
docker cp $GITLAB_CONTAINER:/var/opt/gitlab/backups/$GITLAB_BACKUP_FILE $BACKUP_DIR/

echo "📋 3단계: Docker 볼륨 백업 (선택사항)..."
# Ubuntu 이미지 존재 확인
if docker image inspect ubuntu:latest >/dev/null 2>&1; then
  echo "Ubuntu 이미지 발견 - 볼륨 백업 진행"

  # GitLab 데이터 볼륨 백업
  docker run --rm \
    -v gitlab_data:/data \
    -v $BACKUP_DIR:/backup \
    ubuntu tar czf /backup/gitlab-volumes-data-$DATE.tar.gz -C /data .

  # GitLab 설정 볼륨 백업
  docker run --rm \
    -v gitlab_config:/data \
    -v $BACKUP_DIR:/backup \
    ubuntu tar czf /backup/gitlab-volumes-config-$DATE.tar.gz -C /data .

  # GitLab 로그 볼륨 백업 (선택사항)
  docker run --rm \
    -v gitlab_logs:/data \
    -v $BACKUP_DIR:/backup \
    ubuntu tar czf /backup/gitlab-volumes-logs-$DATE.tar.gz -C /data .
else
  echo "⚠️ Ubuntu 이미지가 없어 볼륨 백업을 건너뜁니다."
  echo "💡 GitLab 내장 백업으로 충분히 복원 가능합니다."
  echo "원하시면 'docker pull ubuntu:latest' 후 다시 실행하세요."
fi

echo "📋 4단계: Docker Compose 설정 백업..."
# Docker Compose 파일 백업 (권한 확인)
if [ -r /opt/gitlab-docker/docker-compose.yml ]; then
  cp /opt/gitlab-docker/docker-compose.yml $BACKUP_DIR/docker-compose-$DATE.yml
else
  echo "⚠️ Docker Compose 파일에 접근할 수 없습니다."
fi

echo "📋 5단계: GitLab secrets 백업..."
# GitLab secrets 파일 백업 (권한 및 파일 존재 확인)
docker exec $GITLAB_CONTAINER cat /etc/gitlab/gitlab-secrets.json > $BACKUP_DIR/gitlab-secrets-$DATE.json 2>/dev/null || echo "⚠️ secrets 파일 없음 또는 접근 불가"

echo "📋 6단계: 백업 검증..."
# 백업 파일 크기 확인
echo "생성된 백업 파일들:"
ls -lh $BACKUP_DIR/*$DATE*

echo "📊 총 백업 크기:"
du -sh $BACKUP_DIR/

echo "📋 7단계: 오래된 백업 정리..."
# 30일 이전 백업 파일 삭제
find $BACKUP_DIR -name "*gitlab*" -type f -mtime +$KEEP_DAYS -delete

echo "📋 8단계: 백업 완료 리포트..."
cat > $BACKUP_DIR/backup-report-$DATE.txt << EOF
GitLab Docker 백업 완료 리포트
===============================
백업 시간: $(date)
GitLab 컨테이너: $GITLAB_CONTAINER

생성된 백업 파일:
- GitLab 애플리케이션: $GITLAB_BACKUP_FILE
- Docker 볼륨 (데이터): gitlab-volumes-data-$DATE.tar.gz
- Docker 볼륨 (설정): gitlab-volumes-config-$DATE.tar.gz
- Docker 볼륨 (로그): gitlab-volumes-logs-$DATE.tar.gz
- Docker Compose: docker-compose-$DATE.yml
- GitLab secrets: gitlab-secrets-$DATE.json

복원 방법:
1. GitLab 컨테이너 정지
2. 볼륨 데이터 복원
3. GitLab 애플리케이션 백업 복원
4. GitLab 재시작

백업 위치: $BACKUP_DIR
===============================
EOF

echo "✅ GitLab 백업 완료!"
echo "📁 백업 위치: $BACKUP_DIR"
echo "📄 상세 리포트: $BACKUP_DIR/backup-report-$DATE.txt"