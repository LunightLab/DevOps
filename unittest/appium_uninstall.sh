#!/bin/bash

echo "🔴 Appium 및 관련 패키지 삭제 시작..."

# 1️⃣ 실행 중인 Appium 프로세스 종료
echo "🛑 실행 중인 Appium 프로세스 종료..."
lsof -i :4723 | awk 'NR>1 {print $2}' | xargs kill -9 2>/dev/null
pkill -f appium
pkill -f node

# 2️⃣ Appium 글로벌 패키지 삭제
echo "🗑️ Appium 글로벌 패키지 삭제..."
npm uninstall -g appium

# 3️⃣ Appium 관련 디렉토리 정리
echo "🧹 Appium 관련 디렉토리 정리..."
rm -rf ~/.appium
rm -rf /usr/local/lib/node_modules/appium
rm -rf /usr/local/bin/appium

# 4️⃣ WebDriverAgent 및 iOS 관련 도구 삭제
echo "🗑️ WebDriverAgent 및 기타 iOS 관련 도구 삭제..."
rm -rf ~/Library/Developer/Xcode/DerivedData/WebDriverAgent-*
rm -rf ~/.npm/_npx
rm -rf ~/.npm/_appium
rm -rf ~/Library/Application\ Support/appium*

# 5️⃣ 추가 iOS 관련 도구 삭제 (필요한 경우)
echo "🗑️ 추가 iOS 관련 도구 삭제..."
brew uninstall applesimutils --ignore-dependencies 2>/dev/null
brew uninstall idb-companion --ignore-dependencies 2>/dev/null
npm uninstall -g ios-deploy

# 6️⃣ npm 캐시 정리
echo "🧹 npm 캐시 정리..."
npm cache clean --force

# 7️⃣ 최종 확인
echo "✅ 삭제 확인..."
if ! command -v appium &> /dev/null; then
    echo "✅ Appium이 성공적으로 삭제되었습니다!"
else
    echo "⚠️ Appium 삭제 실패: 수동 확인 필요"
fi

echo "🔴 Appium 삭제 완료!"