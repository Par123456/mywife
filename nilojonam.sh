#!/bin/bash

clear
Creator="EditeD By: NILO"
echo -e "\e[1;32m$Creator\e[0m"
sleep 0.3
clear
custom_udid="550e8400-e29b-41d4-a716-446655440000"

# Function to decode data
decode() {
    local data="$1"
    local final_string=""
    for key in "${!data[@]}"; do final_string+="$key=${data[$key]}&"
    done echo "${final_string%&}"
}

# Variables for connection pool
pool_size=10
pool_connections=10
pool_max_retries=5
pool_backoff_factor=0.1

# Function to handle errors
handle_error() {
    local restore_key="$1"
    local error_message="$2"
    clear echo -e "\e[1;31mError connecting to the game! - Code: << $restore_key >>\e[0m"
    echo "$error_message"
    exit 1
}

# Function to load account
load_account() {
    local restore_key="$1"
    local models=("SM-A750F" "iPhone12,1" "iPhone12,3" "iPhone13,2" "iPhone14,3")
    local os_versions=("10" "15.4" "15.3" "15.2" "15.1")
    
    local data=(
        ["game_version"]="1.7.10655"
        ["device_name"]="unknown"
        ["os_version"]="${os_versions[RANDOM % ${#os_versions[@]}]}"
        ["model"]="${models[RANDOM % ${#models[@]}]}"
        ["udid"]=$(uuidgen)
        ["store_type"]="iraqapps"
        ["restore_key"]="$restore_key"
        ["os_type"]=2 )
    
    response=$(curl -s -X POST "http://iran.fruitcraft.ir/player/load" -d "$(decode data)" --connect-timeout 5)
    if [[ $? -ne 0 ]]; then
        handle_error "$restore_key" "Connection failed."
    fi
    echo "$response"
}

# Function to update cards
update_cards() {
    cards+=("${cards[0]}")
    unset 'cards[0]'
}

# Function to get enemies
get_enemies() {
    while true; do
        response=$(curl -s "http://iran.fruitcraft.ir/battle/getopponents")
        enemies=$(echo "$response" | jq -r '.data.players | sort_by(.def_power)')
        if [[ -n "$enemies" ]]; then echo "$enemies"
            return
        else echo -e "\e[1;31m• Error searching for enemies!\e[0m"
            sleep 5
        fi done
}

# Function to perform battle
battle() {
    local opponent_id="$1"
    local q="$2"
    local cards="$3"
    local attacks_in_today="$4"
    local data=(
        ["opponent_id"]="$opponent_id"
        ["check"]=$(echo -n "$q" | md5sum | awk '{print $1}')
        ["cards"]=$(echo "$cards" | tr -d ' ')
        ["attacks_in_today"]="$attacks_in_today"
    )
    response=$(curl -s "http://iran.fruitcraft.ir/battle/battle?$(decode data)" --connect-timeout 5)
    echo "$response"
}

# Main attack function
attack() {
    local power="$1"
    local attack_range="$2"
    local delay="$3"
    local win=0
    local lose=0
    local totaldoon=0
    local xp=0
    local q=$(echo "$load" | jq -r '.data.q')

    while [[ "$Creator" == *"T_Ki"* ]]; do
        enemies=$(get_enemies)
        echo -e "\e[1;32m${#enemies[@]} Enemies found...\e[0m"
        for enemy in "${enemies[@]}"; do # Attack logic here...
            sleep "$delay"
        done echo -e "\e[1;32m[TotalDooN: $totaldoon]• The last result ••• Win: $win ••• Lost: $lose ••• Xp: $xp\e[0m"
    done
}

# Main script execution
read -p "• Enter your first account code: " code
load=$(load_account "$code")
cards=($(echo "$load" | jq -r '.data.cards[] | select(.power < 100) | .id'))
if [[ ${#cards[@]} -lt 20 ]]; then
    echo -e "\e[1;31mYou have less than 20 cards in << $(echo "$load" | jq -r '.data.name') >> account!\e[0m"
    exit 1
fi
echo -e "\e[1;32mYou have successfully connected to << $(echo "$load" | jq -r '.data.name') >> account\e[0m"

read -p 'Enter Your Power: ' power
read -p 'Attack count: ' rng
read -p "Enter Delay: " slp

attack "$power" "$rng" "$(echo "$slp / 10" | bc)"
