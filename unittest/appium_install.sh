#!/bin/bash

echo "🚀 Appium 및 관련 패키지 설치 시작..."

# 1️⃣ Homebrew 업데이트
echo "🔄 Homebrew 업데이트..."
brew update

# 2️⃣ Node.js 및 npm 설치 (필요한 경우)
if ! command -v node &> /dev/null; then
    echo "🔧 Node.js 설치 중..."
    brew install node
else
    echo "✅ Node.js가 이미 설치되어 있습니다."
fi

# 3️⃣ Appium 설치
echo "📦 Appium 설치 중..."
npm install -g appium

# 4️⃣ Appium XCUITest 드라이버 설치
echo "📦 XCUITest 드라이버 설치 중..."
appium driver install xcuitest

# 5️⃣ 필수 도구 설치 (iOS 테스트 관련)
echo "🛠️ 필수 iOS 도구 설치 중..."
brew install carthage
brew tap facebook/fb
brew install idb-companion
pip3 install fb-idb
brew tap wix/brew
brew install applesimutils
npm install -g ios-deploy

# 6️⃣ WebDriverAgent 경로 자동 검색 및 초기화
# 그냥 https://github.com/appium/WebDriverAgent.git에서 다운
echo "🔍 WebDriverAgent 경로 검색 중..."
WDA_PATH=$(find ~/.appium /usr/local/lib/node_modules/appium -name WebDriverAgent -type d 2>/dev/null | head -n 1)

if [ -z "$WDA_PATH" ]; then
    echo "❌ WebDriverAgent를 찾을 수 없습니다. 수동으로 확인하세요."
else
    echo "✅ WebDriverAgent 경로: $WDA_PATH"
    cd "$WDA_PATH" || exit
    echo "🔨 WebDriverAgent 초기화..."
    carthage bootstrap --platform iOS
fi

# 7️⃣ Appium Server GUI 설치(https://github.com/appium/appium-desktop/releases/tag/v1.22.3-4)
#echo "🖥️ Appium Server GUI 설치 중..."
#APP_VERSION="2023.11.1"
#APP_NAME="Appium-Server-GUI-${APP_VERSION}-mac.zip"
#APP_URL="https://github.com/appium/appium-desktop/releases/download/v${APP_VERSION}/${APP_NAME}"
#INSTALL_PATH="/Applications"

# Appium Server GUI 다운로드 및 압축 해제
curl -L -o ~/Downloads/${APP_NAME} ${APP_URL}
unzip ~/Downloads/${APP_NAME} -d ~/Downloads/
mv ~/Downloads/Appium-Server-GUI.app "${INSTALL_PATH}/"

# 8️⃣ npm 캐시 정리
echo "🧹 npm 캐시 정리..."
npm cache clean --force

# 9️⃣ 설치 확인
echo "✅ 설치 확인..."
appium -v

echo "🎉 Appium 및 필수 패키지 설치 완료! 🚀"
echo "✅ Appium Server GUI는 '응용 프로그램' 폴더에서 실행할 수 있습니다."