#! /usr/bin/env bash

api_key=
location_name=臺北市

check_dependencies() {
    local code
    code=0

    if ! command -v curl &> /dev/null ; then
        code=1
        printf "No curl installed\n" >&2
    fi

    if ! command -v jq &> /dev/null ; then
        code=1
        printf "No jq installed\n" >&2
    fi

    return "$code"
}

get_cache_directory() {
    local dir
    dir=${XDG_CACHE_HOME:-"$HOME/.cache"}/tmux/dracula/cwa-weather

    [[ ! -d "$dir" ]] && mkdir -p "$dir"

    printf "%s" "$dir"
}

get_latest_cache() {
    local dir
    dir=$(get_cache_directory)

    local cache

    for file in "$dir"/*.json; do
        [[ -f "$file" ]] && cache="$file"
    done

    printf "%s" "$cache"
}

is_valid_cache() {
    local cache
    cache="$1"

    local file_name
    file_name=${cache##*/}

    [[ -z "$cache" || ! "$file_name" =~ [0-9]{10}\.json || ! -f "$cache" ]] && return 1

    # yyyyMMddHH
    local file_date_hour
    file_date_hour=${file_name%%.*}

    local file_date
    file_date="${file_date_hour:0:8}"

    local file_hour
    file_hour="${file_date_hour: -2:2}"
    file_hour=${file_hour#0}

    local date
    date="$(printf "%(%Y%m%d)T")"

    local hour
    hour="$(printf "%(%k)T")"

    [[ "$date" > "$file_date" || $((hour - file_hour)) -ge 3 ]] && return 1
}

call_api() {
    local cache
    cache="$(get_latest_cache)"

    if [[ -n "$cache" && ! $(is_valid_cache "$cache") ]]; then
        rm "$cache"
        cache=""
    fi

    if [[ -z "$cache" ]]; then
        cache=$(printf "%s/%(%Y%m%d%H)T.json" "$(get_cache_directory)")

        if ! curl \
            --fail \
            --silent \
            --header "Accept: application/json" \
            --header "Authorization: $api_key" \
            --url-query locationName="$location_name" \
            --url-query elementName=Wx \
            --url-query elementName=MinT \
            --url-query elementName=MaxT \
            --url-query sort=time \
            --output "$cache" \
            "https://opendata.cwa.gov.tw/api/v1/rest/datastore/F-C0032-001"; then

            printf "curl failed with %d exit code\n" "$?" >&2
            return 1
        fi
    fi

    printf "%s" "$(< "$cache")"
}

check_api_status() {
    local response
    response="$1"

    local api_success
    api_success="$(printf "%s" "$response" | jq '.success == "true"')"

    if [[ "$api_success" == "false" ]]; then
        return 1
    fi
}

get_weather_code() {
    local elements
    elements="$1"

    printf "%s" "$elements" | jq '.[] | if .elementName == "Wx" then .time[0].parameter.parameterValue else empty end | tonumber'
}

get_weather_icon() {
    local code
    code="$1"

    local weather_icons
    weather_icons=(
        [1]="󰖙"
        [2]="󰖕"
        [3]="󰖕"
        [4]="󰖕"
        [5]="󰖐"
        [6]="󰖐"
        [7]="󰖐"
        [8]="󰼳"
        [9]="󰖗"
        [10]="󰖗"
        [11]="󰖗"
        [12]="󰖗"
        [13]="󰖗"
        [14]="󰖖"
        [15]="󰙾"
        [16]="󰙾"
        [17]="󰙾"
        [18]="󰙾"
        [19]="󰼳"
        [20]="󰼳"
        [21]="󰙾"
        [22]="󰙾"
        [23]="󰙿"
        [24]="󰖑"
        [25]="󰖑"
        [26]="󰖑"
        [27]="󰖑"
        [28]="󰖑"
        [29]="󰼳"
        [30]="󰖗"
        [31]="󰖑"
        [32]="󰖑"
        [33]="󰼲"
        [34]="󰙾"
        [35]="󰙾"
        [36]="󰙾"
        [37]="󰙿"
        [38]="󰼳"
        [39]="󰖗"
        [41]="󰙾"
        [42]="󰖘"
    )

    local icon
    icon="${weather_icons[code]}"

    printf "%s" "${icon:-N/A}"
}

get_temperature() {
    local elements
    elements="$1"

    local type
    type="${2,,}"

    local name

    if [[ "$type" == "max" ]]; then
        name=MaxT
    elif [[ "$type" == "min" ]]; then
        name=MinT
    else
        printf "Invalid type: %s\n" "$2" >&2
        return 1
    fi

    printf "%s" "$elements" | jq '.[] | if .elementName == "'"$name"'" then .time[0].parameter.parameterName else empty end | tonumber'
}

check_dependencies || exit 1

response="$(call_api)" || exit 1

if ! check_api_status "$response"; then
    printf "API failed\n" >&2
    exit 1
fi

weather_elements="$(printf "%s" "$response" | jq '.records.location[0].weatherElement')" || exit 1
weather_code="$(get_weather_code "$weather_elements")" || exit 1
weather_icon="$(get_weather_icon "$weather_code")"
max_temp="$(get_temperature "$weather_elements" "max")" || exit 1
min_temp="$(get_temperature "$weather_elements" "min")" || exit 1
avg_temp=$(( (min_temp + max_temp) / 2 ))

printf "%s %d°C" "$weather_icon" "$avg_temp"
