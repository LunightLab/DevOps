#***********************************************************************
#   @title - add_gitignore.sh
#   @description - .gitignore 옵션을 적용하기 위해 캐시된 파일을 제거하고 다시 추가
#   @author - lunight
#********************************************************************** */

#!/bin/sh

# .gitignore 적용을 위한 캐시 초기화
echo "Removing all cached files from Git tracking..."
git rm -r --cached .

# 변경 사항 추가
echo "Adding all files back to Git tracking..."
git add .

# 커밋 실행
echo "Committing changes..."
git commit -m "add option .gitignore"

echo "Done!"