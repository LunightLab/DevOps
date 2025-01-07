#!/bin/zsh

# Usage: ./script.sh <file-path1> <file-path2> ...
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <file-path1> <file-path2> ..."
    exit 1
fi

# Slack API 설정
BOT_TOKEN="xoxb-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
CHANNEL_ID="xxxxxxxxxx" #https://app.slack.com/client/aaaaaaaa/xxxxxxxxxx


for FILE_PATH in "$@"; do
    # 파일 이름 가져오기
    FILE_NAME=$(basename "$FILE_PATH")

    # 파일 존재 확인
    if [ ! -f "$FILE_PATH" ]; then
        echo "Error: File '$FILE_PATH' not found."
        continue
    fi

    # 파일 크기 계산
    FILE_SIZE=$(stat -f%z "$FILE_PATH")
    if [[ -z "$FILE_SIZE" || "$FILE_SIZE" -le 0 ]]; then
        echo "Error: Invalid file size for '$FILE_PATH'."
        continue
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
        echo "Error: Failed to get upload URL for '$FILE_PATH'. Response: $response"
        continue
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

    # Permalink 추출 또는 URL 생성
    permalink=$(echo "$complete_response" | jq -r '.files[0].permalink')

    if [[ -z "$permalink" || "$permalink" == "null" ]]; then
        TEAM_ID=$(echo "$complete_response" | jq -r '.team')
        permalink="https://files.slack.com/files-pri/$TEAM_ID-$FILE_ID/download/$FILE_NAME"
    fi

    # 디버깅 출력
    echo "Complete Response: $complete_response"
    echo "Permalink Extracted: $permalink"

    # Step 4: Slack 메시지 전송
    json_payload=$(cat <<EOF
{
    "channel": "$CHANNEL_ID",
    "text": "ipa report for $FILE_NAME: $permalink"
}
EOF
    )

    curl --interface en1 -X POST \
         -H "Authorization: Bearer $BOT_TOKEN" \
         -H "Content-Type: application/json" \
         --data "$json_payload" \
         https://slack.com/api/chat.postMessage

    echo "File '$FILE_NAME' shared to channel $CHANNEL_ID successfully."
done