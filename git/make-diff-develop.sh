#***********************************************************************
#   @title - add_gitignore.sh
#   @description - .gitignore 옵션을 적용하기 위해 캐시된 파일을 제거하고 다시 추가
#   @author - lunight
#********************************************************************** */

#!/bin/bash

# 저장할 파일명
OUTPUT_FILE="diff-result.txt"

# 현재 브랜치 이름 가져오기
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

# 현재 날짜 가져오기
CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S")

# 상태 코드 설명 표
STATUS_LEGEND="===========================================
Git Diff 상태 코드 설명
-------------------------------------------
A  = Added (새로 추가된 파일)
M  = Modified (수정된 파일)
D  = Deleted (삭제된 파일)
R# = Renamed (파일 이름 변경, #은 유사도)
C# = Copied (기존 파일에서 복사됨, #은 유사도)
T  = Type changed (파일 타입 변경)
U  = Unmerged (병합 충돌 발생)
===========================================
"

# 출력 파일에 브랜치 정보 및 날짜 기록
echo "브랜치: $BRANCH_NAME, 날짜: $CURRENT_DATE" > $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# 상태 코드 설명 추가
echo "$STATUS_LEGEND" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# git diff --name-status 결과 추가
git diff --name-status develop >> $OUTPUT_FILE

# 실행 완료 메시지
echo "Git diff 결과가 $OUTPUT_FILE 파일에 저장되었습니다."