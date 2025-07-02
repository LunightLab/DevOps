#!/bin/bash
# GitLab Docker 복원 스크립트 (수정된 버전)

BACKUP_DIR="$HOME/gitlab-backups"
GITLAB_CONTAINER="gitlab"

if [ $# -eq 0 ]; then
    echo "사용법: $0 <백업날짜> (예: 20250701_143219)"
    echo "사용 가능한 백업:"
    ls $BACKUP_DIR/*gitlab_backup.tar 2>/dev/null | sed 's/.*\///;s/_gitlab_backup.tar//'
    exit 1
fi

BACKUP_DATE=$1
GITLAB_BACKUP_FILE="${BACKUP_DATE}_gitlab_backup.tar"

echo "🔄 GitLab 복원 시작: $BACKUP_DATE"

# 백업 파일들 존재 확인
echo "📋 백업 파일 확인..."
if [ ! -f "$BACKUP_DIR/$GITLAB_BACKUP_FILE" ]; then
    echo "❌ GitLab 백업 파일을 찾을 수 없습니다: $GITLAB_BACKUP_FILE"
    exit 1
fi

echo "✅ 발견된 백업 파일들:"
ls -la $BACKUP_DIR/*$BACKUP_DATE* | grep -v "backup-report"

echo "⚠️ 주의: 현재 GitLab 데이터가 모두 삭제됩니다!"
read -p "계속하시겠습니까? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "복원이 취소되었습니다."
    exit 1
fi

echo "📋 1단계: GitLab 컨테이너 정지..."
cd /opt/gitlab-docker
docker compose down

echo "📋 2단계: 기존 볼륨 제거..."
docker volume rm gitlab_data gitlab_config gitlab_logs 2>/dev/null || true

echo "📋 3단계: 새로운 볼륨 생성..."
docker volume create gitlab_data
docker volume create gitlab_config
docker volume create gitlab_logs

echo "📋 4단계: Docker Compose 파일 복원..."
if [ -f "$BACKUP_DIR/docker-compose-$BACKUP_DATE.yml" ]; then
  cp $BACKUP_DIR/docker-compose-$BACKUP_DATE.yml /opt/gitlab-docker/docker-compose.yml
  echo "✅ Docker Compose 파일 복원 완료"
else
  echo "⚠️ Docker Compose 백업 파일이 없습니다. 기존 파일을 유지합니다."
fi

echo "📋 5단계: GitLab 컨테이너 시작..."
docker compose up -d

echo "📋 6단계: GitLab 완전 시작 대기..."
echo "GitLab이 시작될 때까지 기다리는 중..."
sleep 90

# GitLab이 준비될 때까지 대기
echo "GitLab 서비스 준비 상태 확인 중..."
for i in {1..20}; do
    if docker exec $GITLAB_CONTAINER gitlab-ctl status >/dev/null 2>&1; then
        echo "✅ GitLab 서비스 준비 완료"
        break
    fi
    echo "대기 중... ($i/20)"
    sleep 15
done

echo "📋 7단계: GitLab secrets 파일 복원..."
if [ -f "$BACKUP_DIR/gitlab-secrets-$BACKUP_DATE.json" ]; then
    # GitLab을 잠시 정지
    docker exec $GITLAB_CONTAINER gitlab-ctl stop
    
    # secrets 파일 복원
    docker cp $BACKUP_DIR/gitlab-secrets-$BACKUP_DATE.json $GITLAB_CONTAINER:/etc/gitlab/gitlab-secrets.json
    
    # 권한 설정
    docker exec $GITLAB_CONTAINER chown root:root /etc/gitlab/gitlab-secrets.json
    docker exec $GITLAB_CONTAINER chmod 600 /etc/gitlab/gitlab-secrets.json
    
    # GitLab 재시작
    docker exec $GITLAB_CONTAINER gitlab-ctl start
    echo "✅ GitLab secrets 파일 복원 완료"
    
    # 서비스 안정화 대기
    sleep 30
else
    echo "⚠️ GitLab secrets 백업 파일이 없습니다."
fi

echo "📋 8단계: GitLab 애플리케이션 백업 복원..."
# 백업 파일을 컨테이너로 복사
docker cp $BACKUP_DIR/$GITLAB_BACKUP_FILE $GITLAB_CONTAINER:/var/opt/gitlab/backups/

# 백업 파일 권한 설정
docker exec $GITLAB_CONTAINER chown git:git /var/opt/gitlab/backups/$GITLAB_BACKUP_FILE

# GitLab 백업 복원 (자동 확인 모드)
echo "GitLab 데이터 복원 중... (시간이 걸릴 수 있습니다)"
docker exec $GITLAB_CONTAINER gitlab-backup restore BACKUP=$BACKUP_DATE RAILS_ENV=production

if [ $? -eq 0 ]; then
    echo "✅ GitLab 애플리케이션 백업 복원 완료"
else
    echo "❌ GitLab 백업 복원 중 오류 발생"
    echo "수동으로 복원을 시도하려면:"
    echo "docker exec -it $GITLAB_CONTAINER gitlab-backup restore BACKUP=$BACKUP_DATE"
    exit 1
fi

echo "📋 9단계: GitLab 설정 재구성..."
docker exec $GITLAB_CONTAINER gitlab-ctl reconfigure

echo "📋 10단계: GitLab 재시작..."
docker restart $GITLAB_CONTAINER

echo "📋 11단계: GitLab 완전 시작 대기..."
echo "GitLab 재시작 후 안정화 대기 중..."
sleep 60

# GitLab 서비스들이 모두 시작될 때까지 대기
for i in {1..15}; do
    if docker exec $GITLAB_CONTAINER gitlab-ctl status 2>/dev/null | grep -q "run:"; then
        echo "✅ GitLab 서비스들이 시작되었습니다"
        break
    fi
    echo "서비스 시작 대기 중... ($i/15)"
    sleep 20
done

echo "📋 12단계: GitLab 상태 확인..."
# GitLab 헬스체크
echo "🔍 GitLab 헬스체크 중..."
for i in {1..10}; do
    if curl -f http://localhost/-/health 2>/dev/null; then
        echo "✅ GitLab 웹 서비스 정상"
        break
    fi
    echo "웹 서비스 준비 대기 중... ($i/10)"
    sleep 30
done

# GitLab 내부 상태 확인
echo "🔍 GitLab 내부 상태 확인..."
docker exec $GITLAB_CONTAINER gitlab-rake gitlab:check SANITIZE=true

echo ""
echo "✅ GitLab 복원 완료!"
echo "🌐 접속: http://localhost"
echo ""
echo "📝 복원 후 확인사항:"
echo "1. 웹 브라우저에서 http://localhost 접속"
echo "2. root 계정으로 로그인 시도"
echo "3. 프로젝트 및 데이터 확인"
echo ""
echo "💡 만약 로그인이 안 된다면:"
echo "   docker exec -it gitlab gitlab-rake \"gitlab:password:reset[root]\""
echo ""