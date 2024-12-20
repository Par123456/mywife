#!/bin/bash

# پاک کردن صفحه و نمایش بنر
function print_banner() {
    clear
    local creator="EditeD By: @BesT_KinG"
    echo "$(figlet -f slant "$creator")"
    sleep 0.3
    clear
}

# تبدیل داده‌ها به فرمت query string
function decode_data() {
    local -n data=$1
    local final_string=""
    for key in "${!data[@]}"; do
        final_string+="${key}=${data[$key]}&"
    done
    echo "${final_string%&}"
}

# مدیریت خطاها
function handle_error() {
    local restore_key=$1
    local message=$2
    clear
    echo -e "\e[31mError: $message - Code: << $restore_key >>\e[0m\n"
    exit 1
}

# بارگذاری اطلاعات حساب
function load_account() {
    local restore_key=$1
    local models=("SM-A750F" "iPhone12,1" "iPhone12,3" "iPhone13,2" "iPhone14,3")
    local os_versions=("10" "15.4" "15.3" "15.2" "15.1")

    declare -A data=(
        ["game_version"]="1.7.10655"
        ["device_name"]="unknown"
        ["os_version"]="${os_versions[RANDOM % ${#os_versions[@]}]}"
        ["model"]="${models[RANDOM % ${#models[@]}]}"
        ["udid"]="$(uuidgen)"
        ["store_type"]="iraqapps"
        ["restore_key"]="$restore_key"
        ["os_type"]=2  # اگر از iOS استفاده می‌کنید، os_type را به 1 تغییر دهید
    )

    local response=$(curl -s -X POST -d "$(decode_data data)" "http://iran.fruitcraft.ir/player/load")
    if [[ $? -ne 0 ]]; then
        handle_error "$restore_key" "Failed to load account"
    fi
    echo "$response" | jq .
}

# دریافت لیست دشمنان
function get_enemies() {
    local response
    while true; do
        response=$(curl -s "http://iran.fruitcraft.ir/battle/getopponents")
        if [[ $? -ne 0 ]]; then
            echo -e "\e[31m• Error fetching enemies list!\n\e[33mRetrying in 5 seconds...\n\n\e[0m"
            sleep 5
            continue
        fi
        enemies=$(echo "$response" | jq -c '.data.players | sort_by(.def_power)')
        if [ -n "$enemies" ]; then
            break
        else
            echo -e "\e[31m• No enemies found! Retrying in 5 seconds...\n\n\e[0m"
            sleep 5
        fi
    done
    echo "$enemies"
}

# عملکرد جنگ
function battle() {
    local opponent_id=$1
    local q=$2
    local card=$3
    local attacks_in_today=$4
    local hero_id=$5

    local data="?opponent_id=${opponent_id}&check=$(echo -n "$q" | md5sum | awk '{print $1}')&cards=[$card]&attacks_in_today=${attacks_in_today}"
    if [ -n "$hero_id" ]; then
        data+="&hero_id=${hero_id}"
    fi

    local response=$(curl -s "http://iran.fruitcraft.ir/battle/battle${data}")
    if [[ $? -ne 0 ]]; then
        echo -e "\e[31m• Error performing battle!\n\e[33mRetrying in 5 seconds...\n\n\e[0m"
        sleep 5
        return 1
    fi
    echo "$response" | jq .
}

# عملکرد حمله
function attack() {
    local power=$1
    local attack_range=$2
    local delay=$3
    local q=$(jq -r '.data.q' <<< "$load")

    local win=0
    local lose=0
    local xp=0
    local doon=0
    local totaldoon=0
    declare -A attacked

    while true; do
        local enemies=$(get_enemies)
        echo -e "\e[32m$(echo "$enemies" | jq length) Enemies found...\e[0m"
        echo -e "\e[32m• Your strength is more than $(echo "$enemies" | jq length) people...\e[0m\n\n"

        for enemy in $(echo "$enemies" | jq -c '.[]'); do
            local enemy_id=$(echo "$enemy" | jq -r '.id')
            local def_power=$(echo "$enemy" | jq -r '.def_power')

            if [[ -z "${attacked[$enemy_id]}" ]]; then
                attacked[$enemy_id]=0
            fi

            if [[ $def_power -gt $power || ${attacked[$enemy_id]} -ge 50 ]]; then
                continue
            fi

            for ((i=0; i<attack_range; i++)); do
                if [[ ${attacked[$enemy_id]} -ge 50 ]]; then
                    continue
                fi

                local q_response=$(battle "$enemy_id" "$q" "[${cards[0]}]" "${attacked[$enemy_id]}")
                if [[ $? -ne 0 ]]; then
                    echo -e "\e[31m• Battle failed! Skipping this enemy.\n\n\e[0m"
                    continue
                fi

                local status=$(echo "$q_response" | jq -r '.status')
                local code=$(echo "$q_response" | jq -r '.data.code')

                if [[ $status == "false" ]]; then
                    if [[ $code -eq 122 ]]; then
                        break
                    elif [[ $code -eq 124 ]]; then
                        echo -e "\e[31mError in Attack by the server. Wait 5 seconds...! 124\n\n\e[0m"
                        sleep 200
                        load=$(load_account "$code")
                    else
                        echo "$q_response"
                        continue
                    fi
                fi

                attacked[$enemy_id]=$((attacked[$enemy_id] + 1))

                if [[ $(echo "$q_response" | jq -r '.data.score_added') -ge 0 && $(echo "$q_response" | jq -r '.data.xp_added') -gt 0 ]]; then
                    win=$((win + 1))
                    echo -e "\e[32mResult: You Win! Name: $(echo "$enemy" | jq -r '.name') - Clan: $(echo "$enemy" | jq -r '.tribe_name')\e[0m"
                else
                    attacked[$enemy_id]=300
                    lose=$((lose + 1))
                    echo -e "\e[31mResult: You Lost! Name: $(echo "$enemy" | jq -r '.name') - Clan: $(echo "$enemy" | jq -r '.tribe_name')\e[0m"
                fi

                xp=$((xp + $(echo "$q_response" | jq -r '.data.xp_added')))
                doon=$((doon + $(echo "$q_response" | jq -r '.data.score_added')))
                totaldoon=$(echo "$q_response" | jq -r '.data.weekly_score')
                q=$(echo "$q_response" | jq -r '.data.q')

                sleep "$delay"
            done
            echo -e "\e[32m[TotalDooN: $totaldoon] • The last result • Win: $win • Lost: $lose • Xp: $xp • DoonAdd: $doon\n\n\e[0m"
        done
    done
}

# اجرای برنامه
print_banner

read -rp "Enter your account code: " code

load=$(load_account "$code")

cards=($(echo "$load" | jq -r '.data.cards[] | select(.power < 100) | .id'))

echo -e "\e[32mYou have successfully connected to $(echo "$load" | jq -r '.data.name') account\e[0m"

read -rp "Enter Your Power: " power
read -rp "Attack count: " attack_range
read -rp "Enter Delay: " delay

attack "$power" "$attack_range" "$(bc <<< "$delay / 10")"
