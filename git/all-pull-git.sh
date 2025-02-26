#***********************************************************************
#   @title - all-poll-git.sh
#   @description - Git 저장소를 최신 상태로 유지하고, 각 디렉토리의 크기를 계산하여 파일로 저장
#   @author - lunight
#********************************************************************** */

#!/bin/bash

# Fetch All: 최신 브랜치 정보 가져오기
git fetch --all

# Git Remote Prune: 삭제된 리모트 브랜치 정리
git remote prune origin

#  모든 리모트 브랜치를 로컬에 체크아웃
git branch -r | grep -v "\\->" | while read remote; do
    # 각 브랜치를 로컬에 체크아웃
    branch_name=$(echo "$remote" | sed 's|origin/||')
    echo "Checking out branch: $branch_name"

    # 해당 브랜치가 이미 존재하면 체크아웃, 존재하지 않으면 새로운 브랜치를 생성하고 리모트 브랜치와 연결
    git checkout "$branch_name" || git checkout -b "$branch_name" --track "$remote"
    
    # 최신 변경 사항을 가져옴(--no-rebase 옵션을 사용하여 rebase 없이 병합)
    git pull --no-rebase origin "$branch_name"
done

# 저장소 및 특정 디렉토리 크기 계산
echo "Calculating sizes..."
total_size=$(du -sh . | awk '{print $1}')
project_total_size=$(du -sh SmartVigsiPhone 2>/dev/null | awk '{print $1}')
git_folder_size=$(du -sh .git | awk '{print $1}')
namuh_resource_size=$(du -sh SmartVigsiPhone/PhoneResource/NamuhResource 2>/dev/null | awk '{print $1}')
qv_resource_size=$(du -sh SmartVigsiPhone/PhoneResource/QVResource 2>/dev/null | awk '{print $1}')


# 결과를 size_info.txt 파일에 저장
echo "total_size=$total_size" > size_info.txt
echo "project_total_size=$project_total_size" >> size_info.txt
echo "git_folder_size=$git_folder_size" >> size_info.txt
echo "namuh_resource_size=$namuh_resource_size" >> size_info.txt
echo "qv_resource_size=$qv_resource_size" >> size_info.txt