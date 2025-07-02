
## Ansible install(원격지 Mac)

```
brew install ansible
```

## Ansible ssh key genarate

```sh
# Ansible 전용 키 생성
ssh-keygen -t ed25519 -f ~/.ssh/ansible_key -C "ansible-mac-servers"

# 생성 시 옵션들:
# - 패스워드: 보안을 위해 설정하거나, 자동화를 위해 빈 값으로 둘 수 있음
# - 덮어쓰기: 기존 파일이 있다면 y/n 선택
# 자동화를 위해 빈값으로 생성

# 키 파일 확인
ls -la ~/.ssh/ansible_key*

# 공개키 내용 확인
cat ~/.ssh/ansible_key.pub

```

```sh
# 각 서버에 공개키 복사 (IP 주소를 실제 값으로 변경)
ssh-copy-id -i ~/.ssh/ansible_key.pub mobile@10.88.20.173
ssh-copy-id -i ~/.ssh/ansible_key.pub jenkins@10.88.20.153

# 연결테스트
 lunight > ssh-copy-id -i ~/.ssh/ansible_key.pub mobile@10.88.20.173
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/Users/lunight/.ssh/ansible_key.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
(mobile@10.88.20.173) Password:

Number of key(s) added:        1

Now try logging into the machine, with:   "ssh 'mobile@10.88.20.173'"
and check to make sure that only the key(s) you wanted were added.

 lunight > ssh-copy-id -i ~/.ssh/ansible_key.pub jenkins@10.88.20.153
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/Users/lunight/.ssh/ansible_key.pub"
The authenticity of host '10.88.20.153 (10.88.20.153)' can't be established.
ED25519 key fingerprint is SHA256:CNZoa6gEOrmDjIceFSclqPGyOT7SdGRgtEwT47QFQTo.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
/usr/bin/ssh-copy-id: INFO: attempting to log n with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
(jenkins@10.88.20.153) Password:

Number of key(s) added:        1

Now try logging into the machine, with:   "ssh 'jenkins@10.88.20.153'"
and check to make sure that only the key(s) you wanted were added.

lunight > ssh -i ~/.ssh/ansible_key mobile@10.88.20.173
lunight > ssh -i ~/.ssh/ansible_key jenkins@10.88.20.153
```

# Ansible file tree
``` sh
.
├── README.md
├── ansible.cfg
├── group_vars
│   ├── all.yml
│   ├── ci_servers.yml
│   └── docker_servers.yml
├── host_vars
├── inventory.ini
├── playbooks
│   ├── gitlab-install.yml
│   ├── gitlab-offline-organization.yml
│   ├── gitlab-online-organization.yml
│   ├── initial-setup.yml
│   ├── jenkins-config.yml
│   ├── system-restart.yml
│   └── update-packages.yml
└── script
    ├── gitlab-backup.sh
    └── gitlab-restore.sh
```

## Ansible project directory 생성
```sh
# 프로젝트 디렉토리 생성
mkdir ansible-mac-servers
cd ansible-mac-servers

# 필요한 파일들 생성
touch ansible.cfg 
touch inventory.ini
mkdir playbooks 
mkdir group_vars
mkdir host_vars
```

**1. ansible.cfg (Ansible 설정 파일)**
```
[defaults]
inventory = inventory.ini          # 서버 목록 파일 지정
private_key_file = ~/.ssh/ansible_key  # SSH 키 경로
host_key_checking = False         # SSH 호스트 키 확인 생략 (편의상)
stdout_callback = yaml            # 출력 포맷 (보기 좋게)
```

**2. inventory.ini (서버 목록 파일)**
```sh
# 관리할 서버들의 정보를 정의
[ci_servers]                      # 그룹명
mac-studio-ci ansible_host=10.88.20.153 ansible_user=jenkins

[docker_servers]                  # 그룹명  
mac-studio-docker ansible_host=10.88.20.173 ansible_user=mobile

[all_macs:children]               # 그룹들을 묶는 상위 그룹
ci_servers
docker_servers
```
**역할**: 어떤 서버들을 관리할지 정의하는 서버 목록

**3. playbooks/ (플레이북 디렉토리)**
```sh
playbooks/
├── gitlab-install.yml
├── gitlab-offline-organization.yml
├── gitlab-online-organization.yml
├── initial-setup.yml
├── jenkins-config.yml
├── system-restart.yml
└── update-packages.yml
```
**역할**: 실제 작업을 정의하는 YAML 파일들을 저장

**4. group_vars/ (그룹별 변수 디렉토리)**
```sh
group_vars/
├── all.yml              # 모든 서버에 공통 패키지 추가
├── ci_servers.yml       # CI iOS 서버에만 패키지 추가
└── docker_servers.yml   # Docker(Android) 서버에만 패키지 추가
```

**5. host_vars/ (개별 서버 변수 디렉토리)**
```sh
host_vars/
├── mac-studio-ci.yml        # 특정 서버만의 변수
└── mac-studio-docker.yml    # 특정 서버만의 변수
```

## 테스트

### ansible.cfg
```sh
[defaults]
inventory = inventory.ini
private_key_file = ~/.ssh/ansible_key
host_key_checking = False
retry_files_enabled = False
stdout_callback = yaml
remote_user = mobile
timeout = 30

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
```

### inventory.ini
```sh
# 관리할 서버들의 정보를 정의
[ci_servers]                      # 그룹명
mac-studio-ci ansible_host=XXX.XX.XX.XXX ansible_user=jenkins

[docker_servers]                  # 그룹명
mac-studio-docker ansible_host=ZZ.ZZ.ZZ.ZZZ ansible_user=mobile

[all_macs:children]               # 그룹들을 묶는 상위 그룹
ci_servers
docker_servers

[all_macs:vars]
ansible_python_interpreter=auto

```

### 최초 mac command line install
```sh
# Xcode Command Line Tools 설치(원격으로 install 수행)
ansible all_macs -m shell -a "xcode-select --install"

# Xcode 라이선스 동의 (mac-studio-ci)
ansible mac-studio-ci -m shell -a "sudo xcodebuild -license accept" --become

# Command Line Tools 설치 확인
ansible all_macs -m shell -a "xcode-select -p"

# brew는 원격접속으로 설치!
https://brew.sh/

#  passwordless sudo 설정 후 재시도
ssh -i ~/.ssh/ansible_key mobile@10.88.20.173
echo "mobile ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/mobile

```

### ping test
```sh
# 디렉토리 이동
cd ~/ansible-mac-servers

# 연결 테스트
ansible all_macs -m ping

# 개별 그룹 테스트
ansible ci_servers -m ping
ansible docker_servers -m ping

# 간단한 명령 실행
ansible all_macs -a "whoami"
ansible all_macs -a "hostname"
```
## 환경변수 디렉토리(VARS) 설정

### 플레이북 구조
```sh
group_vars/
├── all.yml        # 기본 환경 + 필수 패키지
├── ci_servers.yml     # 선택적/추가 패키지 설치
└── docker_servers.yml      # Jenkins, Docker 서비스 설정

```

## 패키지 설치하기
### 새 패키지 즉시 설치
```sh
ansible all_macs -m shell -a "
export HOMEBREW_NO_AUTO_UPDATE=1;
/opt/homebrew/bin/brew install vim tmux
"
```

### iOS 서버에만
```sh
ansible ci_servers -m shell -a "
export HOMEBREW_NO_AUTO_UPDATE=1;
/opt/homebrew/bin/brew install swiftlint
"
```
- 만약 관리를 계속해야한다면 group_vars/원하는.yml파일에 추가하고 설치


### 관리자 권한부여
```sh
# Mac Studio CI 서버에서 (jenkins 사용자를 관리자로)
sudo dseditgroup -o edit -a jenkins -t user admin
# 각 서버에 직접 접속해서 passwordless sudo 설정
echo "jenkins ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/jenkins

# Mac Studio Docker 서버에서 (mobile 사용자를 관리자로)  
sudo dseditgroup -o edit -a mobile -t user admin
# 각 서버에 직접 접속해서 passwordless sudo 설정
echo "mobile ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/mobile
```

### Gitlab 초기 패스워드 
```sh
# Docker Compose 디렉토리에서 실행
cd /opt/gitlab-docker
docker exec gitlab cat /etc/gitlab/initial_root_password

# gitlab 복구
cd /opt/gitlab-docker
docker compose up -d

# gitlab 로그확인
docker logs gitlab -f
```

### Docker gitlab 백업 및 복구
```sh
script
    ├── gitlab-backup.sh
    └── gitlab-restore.sh
```
