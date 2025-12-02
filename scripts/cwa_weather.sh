#! /usr/bin/env bash

get_log_directory() {
    local dir
    dir="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/dracula"

    [[ ! -d "$dir" ]] && mkdir -p "$dir"

    printf "%s" "$dir"
}

get_log_file() {
    printf "%s/cwa-weather-%(%Y%m%d)T.log" "$(get_log_directory)"
}

delete_old_log_files() {
    local current_log_file
    current_log_file="$(get_log_file)"

    for file in "$(get_log_directory)"/cwa-weather-*.log; do
        [[ -f "$file" && "$file" != "$current_log_file" ]] && rm "$file"
    done
}

log() {
    local level
    level="$1"

    local msg
    msg="$2"

    local current_level
    current_level=1

    local levels
    levels=(
        [1]=DEBUG
        [2]=INFO
        [3]=WARN
        [4]=ERROR
    )

    local log_file
    log_file="$(get_log_file)"

    [[ $level -lt 1 || $level -gt 4 ]] && return 1

    [[ $current_level -gt $level ]] && return 0

    printf "%(%F %T)T [%5s] %s\n" -1 "${levels["$level"]}" "$msg" >> "$log_file"
}

log_debug() {
    log 1 "$1"
}

log_error() {
    log 4 "$1"
}

check_dependencies() {
    local code
    code=0

    if ! command -v curl &> /dev/null ; then
        code=1
        log_error "No curl installed"
    fi

    if ! command -v jq &> /dev/null ; then
        code=1
        log_error "No jq installed"
    fi

    return "$code"
}

get_cache_directory() {
    local dir
    dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux/dracula/cwa-weather"

    [[ ! -d "$dir" ]] && mkdir -p "$dir"

    printf "%s" "$dir"
}

get_latest_cache() {
    local location
    location="$1"

    local dir
    dir="$(get_cache_directory)"

    local cache

    for file in "${dir}/${location}-"*.json; do
        if [[ -f "$file" ]]; then
            log_debug "Found cache: $file"
            cache="$file"
        fi
    done

    printf "%s" "$cache"
}

is_valid_cache() {
    local cache
    cache="$1"

    local file_name
    file_name=${cache##*/}

    if [[ -z "$cache" || ! "$file_name" =~ .+-[0-9]{10}\.json ]]; then
        log_debug "Invalid cache file name: $cache"
        return 1
    fi

    if [[ ! -f "$cache" ]]; then
        log_debug "Cache file does not exist: $cache"
        return 1
    fi

    # yyyyMMddHH
    local file_date_hour

    # Remove extension
    file_date_hour=${file_name%%.*}

    # Remove location(e.g. 臺北市-)
    file_date_hour=${file_date_hour##*-}

    local file_date
    file_date="${file_date_hour:0:8}"

    local file_hour
    file_hour="${file_date_hour: -2:2}"

    # Remove leading zero
    file_hour=${file_hour#0}

    local date
    date="$(printf "%(%Y%m%d)T")"

    local hour
    hour="$(printf "%(%k)T")"

    if [[ "$date" > "$file_date" || $((hour - file_hour)) -ge 3 ]]; then
        log_debug "Cache expired: $cache. Cache time: ${file_date} ${file_hour}h. Current time: ${date} ${hour}h."
        return 1
    else
        return 0
    fi
}

call_api() {
    local api_key
    api_key="$(get_tmux_option "@dracula-cwa-weather-api-key" "")"

    local location_name
    location_name="$(get_tmux_option "@dracula-cwa-weather-location" "臺北市")"

    local cache
    cache="$(get_latest_cache "$location_name")"

    if [[ -n "$cache" ]] && ! is_valid_cache "$cache"; then
        log_debug "Delete invalid cache: $cache"

        rm "$cache"
        cache=""
    fi

    if [[ -z "$cache" ]]; then
        if [[ -z "$api_key" ]]; then
            log_error "No CWA weather api key"
            return 1
        fi

        cache="$(printf "%s/%s-%(%Y%m%d%H)T.json" "$(get_cache_directory)" "$location_name")"

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

            log_error "curl failed with $? exit code"
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
        [1]=""
        [2]=""
        [3]=""
        [4]=""
        [5]=""
        [6]=""
        [7]=""
        [8]=""
        [9]=""
        [10]=""
        [11]=""
        [12]=""
        [13]=""
        [14]=""
        [15]=""
        [16]=""
        [17]=""
        [18]=""
        [19]=""
        [20]=""
        [21]=""
        [22]=""
        [23]=""
        [24]=""
        [25]=""
        [26]=""
        [27]=""
        [28]=""
        [29]=""
        [30]=""
        [31]=""
        [32]=""
        [33]=""
        [34]=""
        [35]=""
        [36]=""
        [37]=""
        [38]=""
        [39]=""
        [41]=""
        [42]=""
    )

    local icon
    icon="${weather_icons[code]}"

    printf "%s" "${icon:-}"
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
        log_error "Invalid type: $2"
        return 1
    fi

    printf "%s" "$elements" | jq '.[] | if .elementName == "'"$name"'" then .time[0].parameter.parameterName else empty end | tonumber'
}

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir"/utils.sh

check_dependencies || exit 1

delete_old_log_files

response="$(call_api)" || exit 1

if ! check_api_status "$response"; then
    log_error "API failed"
    exit 1
fi

weather_elements="$(printf "%s" "$response" | jq '.records.location[0].weatherElement')" || exit 1
weather_code="$(get_weather_code "$weather_elements")" || exit 1
weather_icon="$(get_weather_icon "$weather_code")"
max_temp="$(get_temperature "$weather_elements" "max")" || exit 1
min_temp="$(get_temperature "$weather_elements" "min")" || exit 1
avg_temp=$(( (min_temp + max_temp) / 2 ))

printf "%s %d°C" "$weather_icon" "$avg_temp"
