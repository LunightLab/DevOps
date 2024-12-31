<!-- 
# ***********************************************************************
# * git clean repository script
# * -----------------------
# * Project Name: git-clean-repository.sh
# * Description: .git clean
# * Author: lunight
# * Date: 2024-12-31
# * Version: 1.0
# * Notes: 로컬 및 원격 장소 클린작업
# ***********************************************************************  
-->

## Git repository 정리

###  로컬 + 원격브랜치 브랜치 삭제

```bash
git branch | grep '^  feature/dev/12.21' | tee /dev/tty | xargs -n 1 -I {} bash -c 'git branch -d {}; git push origin --delete {}'
```

### 원격에 삭제된 브랜치 로컬에서 지우기

```bash
# 원격에 삭제된 브랜치 local에서 지우기
git remote prune origin
git branch -vv | grep ': gone' | awk '{print $1}' | xargs git branch -d

# 병합되지않은 브랜치 삭제
git branch --format="%(refname:short)" | while read branch; do
  if ! git show-ref --verify --quiet refs/remotes/origin/$branch; then
    git branch -D $branch
  fi
done
```

### 로컬 브랜치만 삭제

```bash
it branch | grep '^  feature/sjh' | tee /dev/tty | xargs -n 1 git branch -d
git branch | grep '^  feature/TBD' | tee /dev/tty | xargs -n 1 git branch -d
git branch | grep '^  feature/wsm' | tee /dev/tty | xargs -n 1 git branch -d
git branch | grep '^  feature/dev' | tee /dev/tty | xargs -n 1 git branch -d
```

### Git 가비지 수집 (Garbage Collection)
Git은 히스토리, 브랜치, 태그 등을 삭제해도 객체 데이터가 .git 내부에 남아 있습니다. 이를 제거하려면 git gc 명령어를 사용

```bash
git gc --aggressive --prune=now
```

옵션 설명

• --aggressive: 최적화 수준을 높여 저장소 크기를 줄임.

• --prune=now: 현재 사용되지 않는 모든 객체를 즉시 삭제.


### 대용량 파일 확인

```bash
git rev-list --objects --all | grep "$(git verify-pack -v .git/objects/pack/*.idx | sort -k 3 -n | tail -5 | awk '{print $1}')"

```

### 대용량 파일 제거
```bash
bfg --delete-files "*.a" .
bfg --delete-files "*.framework" .
bfg --delete-files "*.svn-base" .
```

### Git의 히스토리에서 제거 후 정리

```bash
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

### 재압축 및 최적화

```bash 
git repack -a -d --depth=250 --window=250
```

옵션 설명

• -a: 기존의 모든 패킹 객체를 새로 생성.
• -d: 불필요한 패킹 객체 삭제.
• --depth와 --window: 압축 최적화 설정.


### 용량 확인
```bash 
du -sh .git
```


## gitlab garbage collection 삭제하는 방법

### 컨테이너 id 확인

```bash
docker ps
```

### GitLab 컨테이너 접속
```bash
docker exec -it <container_name> /bin/bash
```

### Garbage Collection 실행

```bash
gitlab-rake gitlab:garbage_collect
```

### 프로젝트 ID 확인
GitLab 저장소에서 특정 프로젝트를 대상으로 Housekeeping을 실행하려면 프로젝트 ID가 필요

```bash
gitlab-rails runner "puts Project.all.pluck(:id, :name)"
```

### 특정 프로젝트 GC 실행

```bash
gitlab-rake "gitlab:projects:gc[<project-id>]"
```

### 전체 GitLab 저장소 최적화
```bash
gitlab-rake gitlab:storage:list_projects | xargs -n 1 gitlab-rake "gitlab:projects:gc"
```

### 프로젝트별 저장소 크기 확인:
```bash
gitlab-rails runner "Project.find(<project-id>).statistics"
gitlab-rails runner "Project.find(1).statistics"
```
### 후기..
테스트결과 크게 .. 영향이 있어보이지 않아... new repository를 생성하는게 좋을 것 같다.


