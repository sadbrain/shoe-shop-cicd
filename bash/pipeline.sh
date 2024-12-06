BOT_TOKEN=6741428147:AAHPRcB0-7hlTHaGySeM4z73YVXSirJ8EGg
TAG_PREFIX="od"
GITLAB_TOKEN={git-lab-token}
GITLAB_URL=http://gitlab.mixcredevops.vip

get_updates(){    
  offset="$1"
  response=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=$offset")
  echo "$response"
}

send_message(){
    message="$1"
    curl -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$chat_id" -d "text=$message" > /dev/null
}

rename_tag_by_branch(){
    branch="$1"
    if [ "$branch" == "main" ]; then
        TAG_PREFIX="om"
    else
        TAG_PREFIX="od"
    fi
}

get_project_id(){
    project_name="$1"
    response=$(curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${GITLAB_URL}/api/v4/projects?search=${project_name}")
    project_id=$(echo "$response" | jq -r '.[0].id')
    echo "$project_id"
}

get_tags(){
    project_id="$1"
    curl -s --request GET "${GITLAB_URL}/api/v4/projects/${project_id}/repository/tags" \
        --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}"
}

create_tag(){
    project_id="$1"
    new_tag="$2"
    branch="$3"

    create_tag_response=$(curl -s --request POST "${GITLAB_URL}/api/v4/projects/${project_id}/repository/tags" \
        --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        --form "tag_name=${new_tag}" \
        --form "ref=${branch}")

    if echo "$create_tag_response" | grep -q '"message": "404 Tag was not found"' ; then
        echo "Failed to create tag. Response: $create_tag_response"
        return 1
    else
        echo "Tag ${new_tag} created successfully."
        echo "${new_tag}"
        return 0
    fi

}

get_running_pipelines() {
    project_id="$1"
    response=$(curl --silent --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${GITLAB_URL}/api/v4/projects/${project_id}/pipelines?status=running")
    echo "$response"
}

handle_build() {
    chat_id="$1"
    user_id="$2"
    branch="$3"
    project_name="$4"
    
    user_name=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getChat?chat_id=$chat_id" | jq -r ".result.username")
    current_time=$(date +"%Y-%m-%d %H:%M:%S")
    message="Đang thực hiện lệnh build trên nhánh $branch bởi @$user_name lúc $current_time..."
    send_message "$message"

    #get the project id from project name
    project_id=$(get_project_id "$project_name")
    #-z thuc hiện hành động nếu biến rỗng
    if [ -z "$project_id" ]; then
        message="Project '$project_name' not found."
        send_message "$message"
        return
    fi

    rename_tag_by_branch "$branch"

    tags=$(get_tags "$project_id")
    #[] chỉ định đây là mảng
    # .[] lặp qua các thành phần trong mảng => se lấy những objcet chỉ bắt đầu bằng prefxix
    # sắp xếp thêo tên
    # lấy thằng cuối nó sắp xếp tắng dần
    # lấy ra thuộc tính name như bình thường
    latest_tag=$(echo "$tags" | jq -r --arg prefix "${TAG_PREFIX}_" '[.[] | select(.name | startswith($prefix))] | sort_by(.name) | last | .name')

    #chech biến có chứa giá trị hay không
    if [ -n "$latest_tag" ]; then
        #-o chỉ định in ra dòng mà khớp với biểu thức chính qui thôi 
        #P cho phép sử dụng biểu thức chính qui
        # '\d đại diện cho số'
        #+ có ít nhất 1 ký tự chữ số sẽ khớp với một hoặc nhiều chữ số liên tiếp $ kết thúc chuối
        version_number=$(echo "$latest_tag" | grep -oP '\d+$')
        new_version_number=$((version_number + 1))
    else
        new_version_number=1
    fi

    new_tag="${TAG_PREFIX}_v${new_version_number}"
    tag_name=$(create_tag "$project_id" "$new_tag" "$branch")

    if [ $? -eq 0 ]; then
        sleep 3
        pipeline_url=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/projects/$project_id/pipelines?ref=$new_tag" | jq -r '.[0].web_url')
        sleep 3
        message="Build cho branch '$branch' của project '$project_name' với tag '$new_tag' đã được kích hoạt bởi người dùng $user_name. URL của pipeline: $pipeline_url"
        send_message "$message"
    else
        message="Không thể tạo tag cho branch '$branch' của project '$project_name'."
        send_message "$message"
    fi
}

offset=0
while true; do
    updates=$(get_updates $offset)
    message_count=$(echo "$updates" | jq '.result | length')
    if [ "$message_count" -gt 0 ]; then
        for (( i = 0; i < $message_count; i++ )); do
            chat_id=$(echo "$updates" | jq -r ".result[$i].message.chat.id")
            user_id=$(echo "$updates" | jq -r ".result[$i].message.from.id")
            text=$(echo "$updates" | jq -r ".result[$i].message.text")
            #check xem text co bat dau bang chuoi build hay khong * bat ky thu gi o sau "build "
            if [[ "$text" == "/build "* ]]; then
                params="${text#/build }"
                branch=$(echo "$params" | awk '{print $1}')
                project_name=$(echo "$params" | awk '{print $2}')
                handle_build "$chat_id" "$user_id" "$branch" "$project_name" 
            fi

            update_id=$(echo "$updates" | jq -r ".result[$i].update_id")
            offset=$((update_id + 1))
        done
    fi

    sleep 1
done