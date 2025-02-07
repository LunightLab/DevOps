#!/bin/zsh

# Usage: ./script.sh <file-path>
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file-path>"
    exit 1
fi

# Slack API 설정
FILE_PATH="$1"
FILE_NAME=$(basename "$FILE_PATH")
BOT_TOKEN="xoxb-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
CHANNEL_ID="xxxxxxxxxx" #https://app.slack.com/client/aaaaaaaa/xxxxxxxxxx

# 파일 크기 계산
FILE_SIZE=$(stat -f%z "$FILE_PATH")
if [[ -z "$FILE_SIZE" || "$FILE_SIZE" -le 0 ]]; then
    echo "Error: Invalid file size ($FILE_SIZE)."
    exit 1
fi

# Step 1: 파일 업로드 URL 요청
response=$(curl --interface en1 -s -X POST \
    -H "Authorization: Bearer $BOT_TOKEN" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "filename=$FILE_NAME" \
    --data-urlencode "length=$FILE_SIZE" \
    https://slack.com/api/files.getUploadURLExternal)

UPLOAD_URL=$(echo $response | jq -r '.upload_url')
FILE_ID=$(echo $response | jq -r '.file_id')

if [[ -z "$UPLOAD_URL" || "$UPLOAD_URL" == "null" ]]; then
    echo "Error: Failed to get upload URL."
    exit 1
fi

# Step 2: 파일 업로드
curl --interface en1 --retry 3 --tlsv1.2 -X POST "$UPLOAD_URL" \
    -F file=@"$FILE_PATH" \
    -H "Authorization: Bearer $BOT_TOKEN"

echo "File upload to $UPLOAD_URL completed."

# Step 3: 파일 업로드 완료 요청
complete_response=$(curl --interface en1 -s -X POST \
    -H "Authorization: Bearer $BOT_TOKEN" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "files=[{\"id\":\"$FILE_ID\", \"title\":\"$FILE_NAME\"}]" \
    https://slack.com/api/files.completeUploadExternal)

# 파일 링크 추출
permalink=$(echo "$complete_response" | jq -r '.files[0].permalink')

# Step 4: 파일 링크를 Slack 채널에 메시지로 공유
# --data '{
#         "channel": "'"$CHANNEL_ID"'",
#         "text": "File uploaded successfully! You can access it here: '"$permalink"'"
#     }' \

json_payload=$(cat <<EOF
{
    "channel": "$CHANNEL_ID",
    "text": "ipa report: $permalink"
}
EOF
)

curl --interface en1 -X POST \
     -H "Authorization: Bearer $BOT_TOKEN" \
     -H "Content-Type: application/json" \
     --data "$json_payload" \
     https://slack.com/api/chat.postMessage

echo "File shared to channel $CHANNEL_ID successfully."