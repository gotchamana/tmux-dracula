#! /usr/bin/env bash

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir"/utils.sh

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
    local location
    location="$1"

    local dir
    dir="$(get_cache_directory)"

    local cache

    for file in "${dir}/${location}-"*.json; do
        [[ -f "$file" ]] && cache="$file"
    done

    printf "%s" "$cache"
}

is_valid_cache() {
    local cache
    cache="$1"

    local file_name
    file_name=${cache##*/}

    [[ -z "$cache" || ! "$file_name" =~ .+-[0-9]{10}\.json || ! -f "$cache" ]] && return 1

    # yyyyMMddHH
    local file_date_hour
    file_date_hour=${file_name%%.*}
    file_date_hour=${file_date_hour##*-}

    local file_date
    file_date="${file_date_hour:0:8}"

    local file_hour
    file_hour="${file_date_hour: -2:2}"
    file_hour=${file_hour#0}

    local date
    date="$(printf "%(%Y%m%d)T")"

    local hour
    hour="$(printf "%(%k)T")"

    [[ "$date" > "$file_date" || $((hour - file_hour)) -ge 3 ]] && return 1 || return 0
}

call_api() {
    local api_key
    api_key="$(get_tmux_option "@dracula-cwa-weather-api-key" "")"

    local location_name
    location_name="$(get_tmux_option "@dracula-cwa-weather-location" "臺北市")"

    local cache
    cache="$(get_latest_cache)"

    if [[ -n "$cache" ]] && ! is_valid_cache "$cache"; then
        rm "$cache"
        cache=""
    fi

    if [[ -z "$cache" ]]; then
        if [[ -z "$api_key" ]]; then
            printf "No CWA weather api key\n" >&2
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
    # nf-weather-alien: 
    # nf-weather-aliens: 
    # nf-weather-barometer: 
    # nf-weather-celsius: 
    # nf-weather-cloud: 
    # nf-weather-cloud_down: 
    # nf-weather-cloud_refresh: 
    # nf-weather-cloud_up: 
    # nf-weather-cloudy: 
    # nf-weather-cloudy_gusts: 
    # nf-weather-cloudy_windy: 
    # nf-weather-day_cloudy: 
    # nf-weather-day_cloudy_gusts: 
    # nf-weather-day_cloudy_high: 
    # nf-weather-day_cloudy_windy: 
    # nf-weather-day_fog: 
    # nf-weather-day_hail: 
    # nf-weather-day_haze: 
    # nf-weather-day_light_wind: 
    # nf-weather-day_lightning: 
    # nf-weather-day_rain: 
    # nf-weather-day_rain_mix: 
    # nf-weather-day_rain_wind: 
    # nf-weather-day_showers: 
    # nf-weather-day_sleet: 
    # nf-weather-day_sleet_storm: 
    # nf-weather-day_snow: 
    # nf-weather-day_snow_thunderstorm: 
    # nf-weather-day_snow_wind: 
    # nf-weather-day_sprinkle: 
    # nf-weather-day_storm_showers: 
    # nf-weather-day_sunny: 
    # nf-weather-day_sunny_overcast: 
    # nf-weather-day_thunderstorm: 
    # nf-weather-day_windy: 
    # nf-weather-degrees: 
    # nf-weather-direction_down: 
    # nf-weather-direction_down_left: 
    # nf-weather-direction_down_right: 
    # nf-weather-direction_left: 
    # nf-weather-direction_right: 
    # nf-weather-direction_up: 
    # nf-weather-direction_up_left: 
    # nf-weather-direction_up_right: 
    # nf-weather-dust: 
    # nf-weather-earthquake: 
    # nf-weather-fahrenheit: 
    # nf-weather-fire: 
    # nf-weather-flood: 
    # nf-weather-fog: 
    # nf-weather-gale_warning: 
    # nf-weather-hail: 
    # nf-weather-horizon: 
    # nf-weather-horizon_alt: 
    # nf-weather-hot: 
    # nf-weather-humidity: 
    # nf-weather-hurricane: 
    # nf-weather-hurricane_warning: 
    # nf-weather-lightning: 
    # nf-weather-lunar_eclipse: 
    # nf-weather-meteor: 
    # nf-weather-moon_alt_first_quarter: 
    # nf-weather-moon_alt_full: 
    # nf-weather-moon_alt_new: 
    # nf-weather-moon_alt_third_quarter: 
    # nf-weather-moon_alt_waning_crescent_1: 
    # nf-weather-moon_alt_waning_crescent_2: 
    # nf-weather-moon_alt_waning_crescent_3: 
    # nf-weather-moon_alt_waning_crescent_4: 
    # nf-weather-moon_alt_waning_crescent_5: 
    # nf-weather-moon_alt_waning_crescent_6: 
    # nf-weather-moon_alt_waning_gibbous_1: 
    # nf-weather-moon_alt_waning_gibbous_2: 
    # nf-weather-moon_alt_waning_gibbous_3: 
    # nf-weather-moon_alt_waning_gibbous_4: 
    # nf-weather-moon_alt_waning_gibbous_5: 
    # nf-weather-moon_alt_waning_gibbous_6: 
    # nf-weather-moon_alt_waxing_crescent_1: 
    # nf-weather-moon_alt_waxing_crescent_2: 
    # nf-weather-moon_alt_waxing_crescent_3: 
    # nf-weather-moon_alt_waxing_crescent_4: 
    # nf-weather-moon_alt_waxing_crescent_5: 
    # nf-weather-moon_alt_waxing_crescent_6: 
    # nf-weather-moon_alt_waxing_gibbous_1: 
    # nf-weather-moon_alt_waxing_gibbous_2: 
    # nf-weather-moon_alt_waxing_gibbous_3: 
    # nf-weather-moon_alt_waxing_gibbous_4: 
    # nf-weather-moon_alt_waxing_gibbous_5: 
    # nf-weather-moon_alt_waxing_gibbous_6: 
    # nf-weather-moon_first_quarter: 
    # nf-weather-moon_full: 
    # nf-weather-moon_new: 
    # nf-weather-moon_third_quarter: 
    # nf-weather-moon_waning_crescent_1: 
    # nf-weather-moon_waning_crescent_2: 
    # nf-weather-moon_waning_crescent_3: 
    # nf-weather-moon_waning_crescent_4: 
    # nf-weather-moon_waning_crescent_5: 
    # nf-weather-moon_waning_crescent_6: 
    # nf-weather-moon_waning_gibbous_1: 
    # nf-weather-moon_waning_gibbous_2: 
    # nf-weather-moon_waning_gibbous_3: 
    # nf-weather-moon_waning_gibbous_4: 
    # nf-weather-moon_waning_gibbous_5: 
    # nf-weather-moon_waning_gibbous_6: 
    # nf-weather-moon_waxing_crescent_1: 
    # nf-weather-moon_waxing_crescent_2: 
    # nf-weather-moon_waxing_crescent_3: 
    # nf-weather-moon_waxing_crescent_4: 
    # nf-weather-moon_waxing_crescent_5: 
    # nf-weather-moon_waxing_crescent_6: 
    # nf-weather-moon_waxing_gibbous_1: 
    # nf-weather-moon_waxing_gibbous_2: 
    # nf-weather-moon_waxing_gibbous_3: 
    # nf-weather-moon_waxing_gibbous_4: 
    # nf-weather-moon_waxing_gibbous_5: 
    # nf-weather-moon_waxing_gibbous_6: 
    # nf-weather-moonrise: 
    # nf-weather-moonset: 
    # nf-weather-na: 
    # nf-weather-night_alt_cloudy: 
    # nf-weather-night_alt_cloudy_gusts: 
    # nf-weather-night_alt_cloudy_high: 
    # nf-weather-night_alt_cloudy_windy: 
    # nf-weather-night_alt_hail: 
    # nf-weather-night_alt_lightning: 
    # nf-weather-night_alt_partly_cloudy: 
    # nf-weather-night_alt_rain: 
    # nf-weather-night_alt_rain_mix: 
    # nf-weather-night_alt_rain_wind: 
    # nf-weather-night_alt_showers: 
    # nf-weather-night_alt_sleet: 
    # nf-weather-night_alt_sleet_storm: 
    # nf-weather-night_alt_snow: 
    # nf-weather-night_alt_snow_thunderstorm: 
    # nf-weather-night_alt_snow_wind: 
    # nf-weather-night_alt_sprinkle: 
    # nf-weather-night_alt_storm_showers: 
    # nf-weather-night_alt_thunderstorm: 
    # nf-weather-night_clear: 
    # nf-weather-night_cloudy: 
    # nf-weather-night_cloudy_gusts: 
    # nf-weather-night_cloudy_high: 
    # nf-weather-night_cloudy_windy: 
    # nf-weather-night_fog: 
    # nf-weather-night_hail: 
    # nf-weather-night_lightning: 
    # nf-weather-night_partly_cloudy: 
    # nf-weather-night_rain: 
    # nf-weather-night_rain_mix: 
    # nf-weather-night_rain_wind: 
    # nf-weather-night_showers: 
    # nf-weather-night_sleet: 
    # nf-weather-night_sleet_storm: 
    # nf-weather-night_snow: 
    # nf-weather-night_snow_thunderstorm: 
    # nf-weather-night_snow_wind: 
    # nf-weather-night_sprinkle: 
    # nf-weather-night_storm_showers: 
    # nf-weather-night_thunderstorm: 
    # nf-weather-rain: 
    # nf-weather-rain_mix: 
    # nf-weather-rain_wind: 
    # nf-weather-raindrop: 
    # nf-weather-raindrops: 
    # nf-weather-refresh: 
    # nf-weather-refresh_alt: 
    # nf-weather-sandstorm: 
    # nf-weather-showers: 
    # nf-weather-sleet: 
    # nf-weather-small_craft_advisory: 
    # nf-weather-smog: 
    # nf-weather-smoke: 
    # nf-weather-snow: 
    # nf-weather-snow_wind: 
    # nf-weather-snowflake_cold: 
    # nf-weather-solar_eclipse: 
    # nf-weather-sprinkle: 
    # nf-weather-stars: 
    # nf-weather-storm_showers: 
    # nf-weather-storm_warning: 
    # nf-weather-strong_wind: 
    # nf-weather-sunrise: 
    # nf-weather-sunset: 
    # nf-weather-thermometer: 
    # nf-weather-thermometer_exterior: 
    # nf-weather-thermometer_internal: 
    # nf-weather-thunderstorm: 
    # nf-weather-time_1: 
    # nf-weather-time_10: 
    # nf-weather-time_11: 
    # nf-weather-time_12: 
    # nf-weather-time_2: 
    # nf-weather-time_3: 
    # nf-weather-time_4: 
    # nf-weather-time_5: 
    # nf-weather-time_6: 
    # nf-weather-time_7: 
    # nf-weather-time_8: 
    # nf-weather-time_9: 
    # nf-weather-tornado: 
    # nf-weather-train: 
    # nf-weather-tsunami: 
    # nf-weather-umbrella: 
    # nf-weather-volcano: 
    # nf-weather-wind_beaufort_0: 
    # nf-weather-wind_beaufort_1: 
    # nf-weather-wind_beaufort_10: 
    # nf-weather-wind_beaufort_11: 
    # nf-weather-wind_beaufort_12: 
    # nf-weather-wind_beaufort_2: 
    # nf-weather-wind_beaufort_3: 
    # nf-weather-wind_beaufort_4: 
    # nf-weather-wind_beaufort_5: 
    # nf-weather-wind_beaufort_6: 
    # nf-weather-wind_beaufort_7: 
    # nf-weather-wind_beaufort_8: 
    # nf-weather-wind_beaufort_9: 
    # nf-weather-wind_direction: 
    # nf-weather-wind_east: 
    # nf-weather-wind_north: 
    # nf-weather-wind_north_east: 
    # nf-weather-wind_north_west: 
    # nf-weather-wind_south: 
    # nf-weather-wind_south_east: 
    # nf-weather-wind_south_west: 
    # nf-weather-wind_west: 
    # nf-weather-windy: 

    # 晴天 CLEAR 1
    # 晴時多雲 MOSTLY CLEAR 2
    # 多雲時晴 PARTLY CLEAR 3
    # 多雲 PARTLY CLOUDY 4
    # 多雲時陰 MOSTLY CLOUDY 5
    # 陰時多雲 MOSTLY CLOUDY 6
    # 陰天 CLOUDY 7
    # 多雲陣雨 PARTLY CLOUDY WITH SHOWERS 8
    # 多雲短暫雨 PARTLY CLOUDY WITH OCCASIONAL RAIN 8
    # 多雲短暫陣雨 PARTLY CLOUDY WITH OCCASIONAL SHOWERS 8
    # 午後短暫陣雨 OCCASIONAL AFTERNOON SHOWERS 8
    # 短暫陣雨 OCCASIONAL SHOWERS 8
    # 多雲時晴短暫陣雨 PARTLY CLEAR WITH OCCASIONAL SHOWERS 8
    # 多雲時晴短暫雨 PARTLY CLEAR WITH OCCASIONAL RAIN 8
    # 晴時多雲短暫陣雨 MOSTLY CLEAR WITH OCCASIONAL SHOWERS 8
    # 晴短暫陣雨 CLEAR WITH OCCASIONAL SHOWERS 8
    # 短暫雨 OCCASIONAL RAIN 8
    # 多雲時陰短暫雨 MOSTLY CLOUDY WITH OCCASIONAL RAIN 9
    # 多雲時陰短暫陣雨 MOSTLY CLOUDY WITH OCCASIONAL SHOWERS 9
    # 陰時多雲短暫雨 MOSTLY CLOUDY WITH OCCASIONAL RAIN 10
    # 陰時多雲短暫陣雨 MOSTLY CLOUDY WITH OCCASIONAL SHOWERS 10
    # 雨天 RAINY 11
    # 晴午後陰短暫雨 CLEAR BECOMING CLOUDY WITH OCCASIONAL RAIN IN THE AFTERNOON 11
    # 晴午後陰短暫陣雨 CLEAR BECOMING CLOUDY WITH OCCASIONAL SHOWERS IN THE AFTERNOON 11
    # 陰短暫雨 CLOUDY WITH OCCASIONAL RAIN 11
    # 陰短暫陣雨 CLOUDY WITH OCCASIONAL SHOWERS 11
    # 陰午後短暫陣雨 CLOUDY WITH OCCASIONAL AFTERNOON SHOWERS 11
    # 多雲時陰有雨 MOSTLY CLOUDY WITH RAIN 12
    # 多雲時陰陣雨 MOSTLY CLOUDY WITH SHOWERS 12
    # 晴時多雲陣雨 MOSTLY CLEAR WITH SHOWERS 12
    # 多雲時晴陣雨 PARTLY CLEAR WITH SHOWERS 12
    # 陰時多雲有雨 MOSTLY CLOUDY WITH RAIN 13
    # 陰時多雲有陣雨 MOSTLY CLOUDY WITH SHOWERS 13
    # 陰時多雲陣雨 MOSTLY CLOUDY WITH SHOWERS 13
    # 陰有雨 RAINY 14
    # 陰有陣雨 CLOUDY WITH SHOWERS 14
    # 陰雨 RAINY 14
    # 陰陣雨 CLOUDY WITH SHOWERS 14
    # 陣雨 SHOWERS 14
    # 午後陣雨 AFTERNOON SHOWERS 14
    # 有雨 RAIN 14
    # 多雲陣雨或雷雨 PARTLY CLOUDY WITH SHOWERS OR THUNDERSHOWERS 15
    # 多雲短暫陣雨或雷雨 PARTLY CLOUDY WITH OCCASIONAL SHOWERS OR THUNDERSHOWERS 15
    # 多雲短暫雷陣雨 PARTLY CLOUDY WITH OCCASIONAL THUNDERSHOWERS 15
    # 多雲雷陣雨 PARTLY CLOUDY WITH THUNDERSHOWERS 15
    # 短暫陣雨或雷雨後多雲 CLOUDY WITH OCCASIONAL SHOWERS OR THUNDERSTORMS BECOMING PARTLY CLOUDY 15
    # 短暫雷陣雨後多雲 CLOUDY WITH OCCASIONAL THUNDERSHOWERS BECOMING PARTLY CLOUDY 15
    # 短暫陣雨或雷雨 OCCASIONAL SHOWERS OR THUNDERSTORMS 15
    # 晴時多雲短暫陣雨或雷雨 MOSTLY CLEAR WITH OCCASIONAL SHOWERS OR THUNDERSTORMS 15
    # 晴短暫陣雨或雷雨 CLEAR WITH OCCASIONAL SHOWERS OR THUNDERSTORMS 15
    # 多雲時晴短暫陣雨或雷雨 PARTLY CLEAR WITH OCCASIONAL SHOWERS OR THUNDERSTORMS 15
    # 午後短暫雷陣雨 OCCASIONAL AFTERNOON THUNDERSHOWERS 15
    # 多雲時陰陣雨或雷雨 PARTLY CLOUDY WITH SHOWERS OR THUNDERSTORMS 16
    # 多雲時陰短暫陣雨或雷雨 PARTLY CLOUDY WITH OCCASIONAL SHOWERS OR THUNDERSTORMS 16
    # 多雲時陰短暫雷陣雨 PARTLY CLOUDY WITH OCCASIONAL THUNDERSHOWERS 16
    # 多雲時陰雷陣雨 PARTLY CLOUDY WITH THUNDERSHOWERS 16
    # 晴陣雨或雷雨 CLEAR WITH SHOWERS OR THUNDERSTORMS 16
    # 晴時多雲陣雨或雷雨 MOSTLY CLEAR WITH SHOWERS OR THUNDERSTORMS 16
    # 多雲時晴陣雨或雷雨 PARTLY CLEAR WITH SHOWERS OR THUNDERSTORMS 16
    # 陰時多雲有雷陣雨 MOSTLY CLOUDY WITH THUNDERSHOWERS 17
    # 陰時多雲陣雨或雷雨 MOSTLY CLOUDY WITH SHOWERS OR THUNDERSTORMS 17
    # 陰時多雲短暫陣雨或雷雨 MOSTLY CLOUDY WITH OCCASIONAL SHOWERS OR THUNDERSTORMS 17
    # 陰時多雲短暫雷陣雨 MOSTLY CLOUDY WITH OCCASIONAL THUNDERSHOWERS 17
    # 陰時多雲雷陣雨 MOSTLY CLOUDY WITH THUNDERSHOWERS 17
    # 陰有陣雨或雷雨 CLOUDY WITH SHOWERS OR THUNDERSTORMS 18
    # 陰有雷陣雨 CLOUDY WITH THUNDERSHOWERS 18
    # 陰陣雨或雷雨 CLOUDY WITH SHOWERS OR THUNDERSTORMS 18
    # 陰雷陣雨 CLOUDY WITH THUNDERSHOWERS 18
    # 晴午後陰短暫陣雨或雷雨 CLEAR BECOMING CLOUDY WITH OCCASIONAL SHOWERS OR THUNDERSTORMS IN THE AFTERNOON 18
    # 晴午後陰短暫雷陣雨 CLEAR BECOMING CLOUDY WITH OCCASIONAL THUNDERSHOWERS IN THE AFTERNOON 18
    # 陰短暫陣雨或雷雨 CLOUDY WITH OCCASIONAL SHOWERS OR THUNDERSTORMS 18
    # 陰短暫雷陣雨 CLOUDY WITH OCCASIONAL THUNDERSHOWERS 18
    # 雷雨 THUNDERSTORMS 18
    # 陣雨或雷雨後多雲 CLOUDY WITH SHOWERS OR THUNDERSTORMS BECOMING PARTLY CLOUDY 18
    # 陰陣雨或雷雨後多雲 CLOUDY WITH SHOWERS OR THUNDERSTORMS BECOMING PARTLY CLOUDY 18
    # 陰短暫陣雨或雷雨後多雲 CLOUDY WITH OCCASIONAL SHOWERS OR THUNDERSTORMS BECOMING PARTLY CLOUDY 18
    # 陰短暫雷陣雨後多雲 CLOUDY WITH OCCASIONAL THUNDERSHOWERS BECOMING PARTLY CLOUDY 18
    # 陰雷陣雨後多雲 CLOUDY WITH THUNDERSHOWERS BECOMING PARTLY CLOUDY 18
    # 雷陣雨後多雲 CLOUDY WITH THUNDERSHOWERS BECOMING PARTLY CLOUDY 18
    # 陣雨或雷雨 SHOWERS OR THUNDERSTORMS 18
    # 雷陣雨 THUNDERSHOWERS 18
    # 午後雷陣雨 AFTERNOON THUNDERSHOWERS 18
    # 晴午後多雲局部雨 CLEAR BECOMING PARTLY CLOUDY WITH LOCAL RAIN IN THE AFTERNOON 19
    # 晴午後多雲局部陣雨 CLEAR BECOMING PARTLY CLOUDY WITH LOCAL RAIN IN THE AFTERNOON 19
    # 晴午後多雲局部短暫雨 CLEAR BECOMING PARTLY CLOUDY WITH LOCAL RAIN IN THE AFTERNOON 19
    # 晴午後多雲局部短暫陣雨 CLEAR BECOMING PARTLY CLOUDY WITH LOCAL RAIN IN THE AFTERNOON 19
    # 晴午後多雲短暫雨 CLEAR BECOMING PARTLY CLOUDY WITH OCCASIONAL RAIN IN THE AFTERNOON 19
    # 晴午後多雲短暫陣雨 CLEAR BECOMING PARTLY CLOUDY WITH OCCASIONAL RAIN IN THE AFTERNOON 19
    # 晴午後局部雨 CLEAR WITH LOCAL AFTERNOON RAIN 19
    # 晴午後局部陣雨 CLEAR WITH LOCAL AFTERNOON RAIN 19
    # 晴午後局部短暫雨 CLEAR WITH OCCASIONAL AFTERNOON RAIN 19
    # 晴午後局部短暫陣雨 CLEAR WITH OCCASIONAL AFTERNOON RAIN 19
    # 晴午後陣雨 CLEAR WITH AFTERNOON SHOWERS 19
    # 晴午後短暫雨 CLEAR WITH OCCASIONAL AFTERNOON RAIN 19
    # 晴午後短暫陣雨 CLEAR WITH OCCASIONAL AFTERNOON SHOWERS 19
    # 晴時多雲午後短暫陣雨 MOSTLY CLEAR WITH OCCASIONAL SHOWERS IN THE AFTERNOON 19
    # 多雲午後局部雨 PARTLY CLOUDY WITH LOCAL AFTERNOON RAIN 20
    # 多雲午後局部陣雨 PARTLY CLOUDY WITH LOCAL AFTERNOON SHOWERS 20
    # 多雲午後局部短暫雨 PARTLY CLOUDY WITH LOCAL AFTERNOON RAIN 20
    # 多雲午後局部短暫陣雨 PARTLY CLOUDY WITH LOCAL AFTERNOON SHOWERS 20
    # 多雲午後陣雨 PARTLY CLOUDY WITH AFTERNOON SHOWERS 20
    # 多雲午後短暫雨 PARTLY CLOUDY WITH OCCASIONAL AFTERNOON RAIN 20
    # 多雲午後短暫陣雨 PARTLY CLOUDY WITH OCCASIONAL AFTERNOON SHOWERS 20
    # 多雲時陰午後短暫陣雨 MOSTLY CLOUDY WITH OCCASIONAL SHOWERS IN THE AFTERNOON 20
    # 陰時多雲午後短暫陣雨 MOSTLY CLOUDY WITH OCCASIONAL SHOWERS IN THE AFTERNOON 20
    # 多雲時晴午後短暫陣雨 PARTLY CLEAR WITH OCCASIONAL SHOWERS IN THE AFTERNOON 20
    # 晴午後多雲陣雨或雷雨 CLEAR BECOMING PARTLY CLOUDY WITH SHOWERS OR THUNDERSTORMS IN THE AFTERNOON 21
    # 晴午後多雲雷陣雨 CLEAR BECOMING PARTLY CLOUDY WITH THUNDERSHOWERS IN THE AFTERNOON 21
    # 晴午後陣雨或雷雨 CLEAR WITH AFTERNOON SHOWERS OR THUNDERSTORMS 21
    # 晴午後雷陣雨 CLEAR WITH AFTERNOON THUNDERSHOWERS 21
    # 晴午後多雲局部陣雨或雷雨 CLEAR BECOMING PARTLY CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS IN THE AFTERNOON 21
    # 晴午後多雲局部短暫陣雨或雷雨 CLEAR BECOMING PARTLY CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS IN THE AFTERNOON 21
    # 晴午後多雲局部短暫雷陣雨 CLEAR BECOMING PARTLY CLOUDY WITH LOCAL THUNDERSHOWERS IN THE AFTERNOON 21
    # 晴午後多雲局部雷陣雨 CLEAR BECOMING PARTLY CLOUDY WITH LOCAL THUNDERSHOWERS IN THE AFTERNOON 21
    # 晴午後多雲短暫陣雨或雷雨 CLEAR BECOMING PARTLY CLOUDY WITH OCCASIONAL SHOWERS OR THUNDERSTORMS IN THE AFTERNOON 21
    # 晴午後多雲短暫雷陣雨 CLEAR BECOMING PARTLY CLOUDY WITH OCCASIONAL THUNDERSHOWERS IN THE AFTERNOON 21
    # 晴午後局部短暫雷陣雨 CLEAR WITH LOCAL AFTERNOON THUNDERSHOWERS 21
    # 晴午後局部雷陣雨 CLEAR WITH LOCAL AFTERNOON THUNDERSHOWERS 21
    # 晴午後短暫雷陣雨 CLEAR WITH OCCASIONAL AFTERNOON THUNDERSHOWERS 21
    # 晴雷陣雨 CLEAR WITH THUNDERSHOWERS 21
    # 晴時多雲雷陣雨 MOSTLY CLEAR WITH THUNDERSHOWERS 21
    # 晴時多雲午後短暫雷陣雨 MOSTLY CLEAR WITH OCCASIONAL SHOWERS OR THUNDERSTORMS IN THE AFTERNOON 21
    # 多雲午後局部陣雨或雷雨 PARTLY CLOUDY WITH LOCAL AFTERNOON SHOWERS OR THUNDERSTORMS 22
    # 多雲午後局部短暫陣雨或 雷雨 PARTLY CLOUDY WITH LOCAL AFTERNOON SHOWERS OR THUNDERSTORMS 22
    # 多雲午後局部短暫雷陣雨 PARTLY CLOUDY WITH LOCAL AFTERNOON THUNDERSHOWERS 22
    # 多雲午後局部雷陣雨 PARTLY CLOUDY WITH LOCAL AFTERNOON THUNDERSHOWERS 22
    # 多雲午後陣雨或雷雨 PARTLY CLOUDY WITH AFTERNOON THUNDERSTORMS OR SHOWERS 22
    # 多雲午後短暫陣雨或雷雨 PARTLY CLOUDY WITH OCCASIONAL AFTERNOON SHOWERS OR THUNDERSTORMS 22
    # 多雲午後短暫雷陣雨 PARTLY CLOUDY WITH OCCASIONAL AFTERNOON THUNDERSHOWERS 22
    # 多雲午後雷陣雨 PARTLY CLOUDY WITH AFTERNOON THUNDERSHOWERS 22
    # 多雲時晴雷陣雨 PARTLY CLEAR WITH OCCASIONAL SHOWERS OR THUNDERSTORMS 22
    # 多雲時晴午後短暫雷陣雨 PARTLY CLEAR WITH OCCASIONAL SHOWERS OR THUNDERSTORMS IN THE AFTERNOON 22
    # 多雲時陰午後短暫雷陣雨 MOSTLY CLOUDY WITH OCCASIONAL SHOWERS OR THUNDERSTORMS IN THE AFTERNOON 22
    # 陰時多雲午後短暫雷陣雨 MOSTLY CLOUDY WITH OCCASIONAL SHOWERS OR THUNDERSTORMS IN THE AFTERNOON 22
    # 陰午後短暫雷陣雨 CLOUDY WITH OCCASIONAL SHOWERS OR THUNDERSTORMS IN THE AFTERNOON 22
    # 多雲局部陣雨或雪 PARTLY CLOUDY WITH LOCAL SHOWERS OR SNOW 23
    # 多雲時陰有雨或雪 MOSTLY CLOUDY WITH RAIN OR SNOW 23
    # 多雲時陰短暫雨或雪 MOSTLY CLOUDY WITH OCCASIONAL RAIN OR SNOW 23
    # 多雲短暫雨或雪 PARTLY CLOUDY WITH OCCASIONAL RAIN OR SNOW 23
    # 陰有雨或雪 CLOUDY WITH RAIN OR SNOW 23
    # 陰時多雲有雨或雪 MOSTLY CLOUDY WITH RAIN OR SNOW 23
    # 陰時多雲短暫雨或雪 MOSTLY CLOUDY WITH OCCASIONAL RAIN OR SNOW 23
    # 陰短暫雨或雪 CLOUDY WITH OCCASIONAL RAIN OR SNOW 23
    # 多雲時陰有雪 MOSTLY CLOUDY WITH SNOW 23
    # 多雲時陰短暫雪 MOSTLY CLOUDY WITH OCCASIONAL SNOW 23
    # 多雲短暫雪 PARTLY CLOUDY WITH OCCASIONAL SNOW 23
    # 陰有雪 CLOUDY WITH SNOW 23
    # 陰時多雲有雪 MOSTLY CLOUDY WITH SNOW 23
    # 陰時多雲短暫雪 MOSTLY CLOUDY WITH OCCASIONAL SNOW 23
    # 陰短暫雪 CLOUDY WITH OCCASIONAL SNOW 23
    # 有雨或雪 RAIN OR SNOW 23
    # 有雨或短暫雪 RAIN OR OCCASIONAL SNOW 23
    # 陰有雨或短暫雪 CLOUDY WITH RAIN OR OCCASIONAL SNOW 23
    # 陰時多雲有雨或短暫雪 MOSTLY CLOUDY WITH RAIN OR OCCASIONAL SNOW 23
    # 多雲時陰有雨或短暫雪 MOSTLY CLOUDY WITH RAIN OR OCCASIONAL SNOW 23
    # 多雲有雨或短暫雪 PARTLY CLOUDY WITH RAIN OR OCCASIONAL SNOW 23
    # 多雲有雨或雪 PARTLY CLOUDY WITH RAIN OR SNOW 23
    # 多雲時晴有雨或雪 PARTLY CLEAR WITH RAIN OR SNOW 23
    # 晴時多雲有雨或雪 MOSTLY CLEAR WITH RAIN OR SNOW 23
    # 晴有雨或雪 CLEAR WITH RAIN OR SNOW 23
    # 短暫雨或雪 OCCASIONAL RAIN OR SNOW 23
    # 多雲時晴短暫雨或雪 PARTLY CLEAR WITH OCCASIONAL RAIN OR SNOW 23
    # 晴時多雲短暫雨或雪 MOSTLY CLEAR WITH OCCASIONAL RAIN OR SNOW 23
    # 晴短暫雨或雪 CLEAR WITH OCCASIONAL RAIN OR SNOW 23
    # 有雪 SNOW 23
    # 多雲有雪 PARTLY CLOUDY WITH SNOW 23
    # 多雲時晴有雪 PARTLY CLEAR WITH SNOW 23
    # 晴時多雲有雪 MOSTLY CLEAR WITH SNOW 23
    # 晴有雪 CLEAR WITH SNOW 23
    # 短暫雪 OCCASIONAL SNOW 23
    # 多雲時晴短暫雪 PARTLY CLEAR WITH OCCASIONAL SNOW 23
    # 晴時多雲短暫雪 MOSTLY CLEAR WITH OCCASIONAL SNOW 23
    # 晴短暫雪 CLEAR WITH OCCASIONAL SNOW 23
    # 晴有霧 CLEAR WITH FOG 24
    # 晴晨霧 CLEAR WITH MORNING FOG 24
    # 晴時多雲有霧 MOSTLY CLEAR WITH FOG 25
    # 晴時多雲晨霧 MOSTLY CLEAR WITH MORNING FOG 25
    # 多雲時晴有霧 PARTLY CLEAR WITH FOG 26
    # 多雲時晴晨霧 PARTLY CLOUDY WITH MORNING FOG 26
    # 多雲有霧 PARTLY CLOUDY WITH FOG 27
    # 多雲晨霧 PARTLY CLOUDY WITH MORNING FOG 27
    # 有霧 WITH FOG 27
    # 晨霧 MORNING FOG 27
    # 陰有霧 CLOUDY WITH FOG 28
    # 陰晨霧 CLOUDY WITH MORNING FOG 28
    # 多雲時陰有霧 MOSTLY CLOUDY WITH FOG 28
    # 多雲時陰晨霧 MOSTLY CLOUDY WITH MORNING FOG 28
    # 陰時多雲有霧 MOSTLY CLOUDY WITH FOG 28
    # 陰時多雲晨霧 MOSTLY CLOUDY WITH MORNING FOG 28
    # 多雲局部雨 PARTLY CLOUDY WITH LOCAL RAIN 29
    # 多雲局部陣雨 PARTLY CLOUDY WITH LOCAL SHOWERS 29
    # 多雲局部短暫雨 PARTLY CLOUDY WITH LOCAL RAIN 29
    # 多雲局部短暫陣雨 PARTLY CLOUDY WITH LOCAL SHOWERS 29
    # 多雲時陰局部雨 MOSTLY CLOUDY WITH LOCAL RAIN 30
    # 多雲時陰局部陣雨 MOSTLY CLOUDY WITH LOCAL SHOWERS 30
    # 多雲時陰局部短暫雨 MOSTLY CLOUDY WITH LOCAL RAIN 30
    # 多雲時陰局部短暫陣雨 MOSTLY CLOUDY WITH LOCAL SHOWERS 30
    # 晴午後陰局部雨 CLEAR BECOMING CLOUDY WITH LOCAL RAIN IN THE AFTERNOON 30
    # 晴午後陰局部陣雨 CLEAR BECOMING CLOUDY WITH LOCAL SHOWERS IN THE AFTERNOON 30
    # 晴午後陰局部短暫雨 CLEAR BECOMING CLOUDY WITH LOCAL RAIN IN THE AFTERNOON 30
    # 晴午後陰局部短暫陣雨 CLEAR BECOMING CLOUDY WITH LOCAL SHOWERS IN THE AFTERNOON 30
    # 陰局部雨 CLOUDY WITH LOCAL RAIN 30
    # 陰局部陣雨 CLOUDY WITH LOCAL SHOWERS 30
    # 陰局部短暫雨 CLOUDY WITH LOCAL RAIN 30
    # 陰局部短暫陣雨 CLOUDY WITH LOCAL SHOWERS 30
    # 陰時多雲局部雨 MOSTLY CLOUDY WITH LOCAL RAIN 30
    # 陰時多雲局部陣雨 MOSTLY CLOUDY WITH LOCAL SHOWERS 30
    # 陰時多雲局部短暫雨 MOSTLY CLOUDY WITH LOCAL RAIN 30
    # 陰時多雲局部短暫陣雨 MOSTLY CLOUDY WITH LOCAL SHOWERS 30
    # 多雲有霧有局部雨 PARTLY CLOUDY WITH FOG AND LOCAL RAIN 31
    # 多雲有霧有局部陣雨 PARTLY CLOUDY WITH FOG AND LOCAL SHOWERS 31
    # 多雲有霧有局部短暫雨 PARTLY CLOUDY WITH FOG AND LOCAL RAIN 31
    # 多雲有霧有局部短暫陣雨 PARTLY CLOUDY WITH FOG AND LOCAL SHOWERS 31
    # 多雲有霧有陣雨 PARTLY CLOUDY WITH FOG AND RAIN 31
    # 多雲有霧有短暫雨 PARTLY CLOUDY WITH FOG AND OCCASIONAL RAIN 31
    # 多雲有霧有短暫陣雨 PARTLY CLOUDY WITH FOG AND OCCASIONAL SHOWERS 31
    # 多雲局部雨有霧 PARTLY CLOUDY WITH LOCAL RAIN AND FOG 31
    # 多雲局部雨晨霧 PARTLY CLOUDY WITH LOCAL RAIN AND FOG IN THE MORNING 31
    # 多雲局部陣雨有霧 PARTLY CLOUDY WITH LOCAL SHOWERS AND FOG 31
    # 多雲局部陣雨晨霧 PARTLY CLOUDY WITH LOCAL SHOWERS AND MORNING FOG 31
    # 多雲局部短暫雨有霧 PARTLY CLOUDY WITH LOCAL RAIN AND FOG 31
    # 多雲局部短暫雨晨霧 PARTLY CLOUDY WITH LOCAL RAIN AND MORNING FOG 31
    # 多雲局部短暫陣雨有霧 PARTLY CLOUDY WITH LOCAL SHOWERS AND FOG 31
    # 多雲局部短暫陣雨晨霧 PARTLY CLOUDY WITH LOCAL SHOWERS AND MORNING FOG 31
    # 多雲陣雨有霧 PARTLY CLOUDY WITH SHOWERS AND FOG 31
    # 多雲短暫雨有霧 PARTLY CLOUDY WITH OCCASIONAL RAIN AND FOG 31
    # 多雲短暫雨晨霧 PARTLY CLOUDY WITH OCCASIONAL RAIN AND FOG IN THE MORNING 31
    # 多雲短暫陣雨有霧 PARTLY CLOUDY WITH OCCASIONAL SHOWERS AND FOG 31
    # 多雲短暫陣雨晨霧 PARTLY CLOUDY WITH OCCASIONAL SHOWERS AND MORNING FOG 31
    # 有霧有短暫雨 FOG AND OCCASIONAL RAIN 31
    # 有霧有短暫陣雨 FOG AND OCCASIONAL SHOWERS 31
    # 多雲時陰有霧有局部雨 MOSTLY CLOUDY WITH FOG AND LOCAL RAIN 32
    # 多雲時陰有霧有局部陣雨 MOSTLY CLOUDY WITH FOG AND LOCAL SHOWERS 32
    # 多雲時陰有霧有局部短暫雨 MOSTLY CLOUDY WITH FOG AND LOCAL RAIN 32
    # 多雲時陰有霧有局部短暫陣雨 MOSTLY CLOUDY WITH FOG AND LOCAL SHOWERS 32
    # 多雲時陰有霧有陣雨 MOSTLY CLOUDY WITH FOG AND SHOWERS 32
    # 多雲時陰有霧有短暫雨 MOSTLY CLOUDY WITH FOG AND OCCASIONAL RAIN 32
    # 多雲時陰有霧有短暫陣雨 MOSTLY CLOUDY WITH FOG AND OCCASIONAL SHOWERS 32
    # 多雲時陰局部雨有霧 MOSTLY CLOUDY WITH LOCAL RAIN AND FOG 32
    # 多雲時陰局部陣雨有霧 MOSTLY CLOUDY WITH LOCAL SHOWERS AND FOG 32
    # 多雲時陰局部短暫雨有霧 MOSTLY CLOUDY WITH LOCAL RAIN AND FOG 32
    # 多雲時陰局部短暫陣雨有霧 MOSTLY CLOUDY WITH LOCAL SHOWERS AND FOG 32
    # 多雲時陰陣雨有霧 MOSTLY CLOUDY WITH SHOWERS AND FOG 32
    # 多雲時陰短暫雨有霧 MOSTLY CLOUDY WITH OCCASIONAL RAIN AND FOG 32
    # 多雲時陰短暫雨晨霧 MOSTLY CLOUDY WITH OCCASIONAL RAIN AND FOG IN THE MORNING 32
    # 多雲時陰短暫陣雨有霧 MOSTLY CLOUDY WITH OCCASIONAL SHOWERS AND FOG 32
    # 多雲時陰短暫陣雨晨霧 MOSTLY CLOUDY WITH OCCASIONAL SHOWERS AND MORNING FOG 32
    # 陰有霧有陣雨 CLOUDY WITH FOG AND SHOWERS 32
    # 陰局部雨有霧 CLOUDY WITH LOCAL RAIN AND FOG 32
    # 陰局部陣雨有霧 CLOUDY WITH LOCAL SHOWERS AND FOG 32
    # 陰局部短暫陣雨有霧 CLOUDY WITH LOCAL SHOWERS AND FOG 32
    # 陰時多雲有霧有局部雨 MOSTLY CLOUDY WITH FOG AND LOCAL RAIN 32
    # 陰時多雲有霧有局部陣雨 MOSTLY CLOUDY WITH FOG AND LOCAL SHOWERS 32
    # 陰時多雲有霧有局部短暫雨 MOSTLY CLOUDY WITH FOG AND LOCAL RAIN 32
    # 陰時多雲有霧有局部短暫陣雨 MOSTLY CLOUDY WITH FOG AND LOCAL SHOWERS 32
    # 陰時多雲有霧有陣雨 MOSTLY CLOUDY WITH FOG AND SHOWERS 32
    # 陰時多雲有霧有短暫雨 MOSTLY CLOUDY WITH FOG AND OCCASIONAL RAIN 32
    # 陰時多雲有霧有短暫陣雨 MOSTLY CLOUDY WITH FOG AND OCCASIONAL SHOWERS 32
    # 陰時多雲局部雨有霧 MOSTLY CLOUDY WITH LOCAL RAIN AND FOG 32
    # 陰時多雲局部陣雨有霧 MOSTLY CLOUDY WITH LOCAL SHOWERS AND FOG 32
    # 陰時多雲局部短暫雨有霧 MOSTLY CLOUDY WITH LOCAL RAIN AND FOG 32
    # 陰時多雲局部短暫陣雨有 霧 MOSTLY CLOUDY WITH LOCAL SHOWERS AND FOG 32
    # 陰時多雲陣雨有霧 MOSTLY CLOUDY WITH SHOWERS AND FOG 32
    # 陰時多雲短暫雨有霧 MOSTLY CLOUDY WITH OCCASIONAL RAIN AND FOG 32
    # 陰時多雲短暫雨晨霧 MOSTLY CLOUDY WITH OCCASIONAL RAIN AND FOG IN THE MORNING 32
    # 陰時多雲短暫陣雨有霧 MOSTLY CLOUDY WITH OCCASIONAL SHOWERS AND FOG 32
    # 陰時多雲短暫陣雨晨霧 MOSTLY CLOUDY WITH OCCASIONAL SHOWERS AND MORNING FOG 32
    # 陰陣雨有霧 CLOUDY WITH SHOWERS AND FOG 32
    # 陰短暫雨有霧 CLOUDY WITH OCCASIONAL RAIN AND FOG 32
    # 陰短暫雨晨霧 CLOUDY WITH OCCASIONAL RAIN AND MORNING FOG 32
    # 陰短暫陣雨有霧 CLOUDY WITH OCCASIONAL SHOWERS AND FOG 32
    # 陰短暫陣雨晨霧 CLOUDY WITH OCCASIONAL SHOWERS AND MORNING FOG 32
    # 多雲局部陣雨或雷雨 PARTLY CLOUDY WITH LOCAL SHOWERS OR THUNDERSHOWERS 33
    # 多雲局部短暫陣雨或雷雨 PARTLY CLOUDY WITH LOCAL SHOWERS OR THUNDERSHOWERS 33
    # 多雲局部短暫雷陣雨 PARTLY CLOUDY WITH LOCAL THUNDERSHOWERS 33
    # 多雲局部雷陣雨 PARTLY CLOUDY WITH LOCAL THUNDERSHOWERS 33
    # 多雲時陰局部陣雨或雷雨 PARTLY CLOUDY WITH LOCAL SHOWERS OR THUNDERSHOWERS 34
    # 多雲時陰局部短暫陣雨或雷雨 PARTLY CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS 34
    # 多雲時陰局部短暫雷陣雨 PARTLY CLOUDY WITH LOCAL THUNDERSHOWERS 34
    # 多雲時陰局部雷陣雨 PARTLY CLOUDY WITH LOCAL THUNDERSHOWERS 34
    # 晴午後陰局部陣雨或雷雨 CLEAR BECOMING CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS IN THE AFTERNOON 34
    # 晴午後陰局部短暫陣雨或雷雨 CLEAR BECOMING CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS IN THE AFTERNOON 34
    # 晴午後陰局部短暫雷陣雨 CLEAR BECOMING CLOUDY WITH LOCAL THUNDERSHOWERS IN THE AFTERNOON 34
    # 晴午後陰局部雷陣雨 CLEAR BECOMING CLOUDY WITH LOCAL THUNDERSHOWERS IN THE AFTERNOON 34
    # 陰局部陣雨或雷雨 CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS 34
    # 陰局部短暫陣雨或雷雨 CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS 34
    # 陰局部短暫雷陣雨 CLOUDY WITH LOCAL THUNDERSHOWERS 34
    # 陰局部雷陣雨 CLOUDY WITH LOCAL THUNDERSHOWERS 34
    # 陰時多雲局部陣雨或雷雨 MOSTLY CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS 34
    # 陰時多雲局部短暫陣雨或雷雨 MOSTLY CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS 34
    # 陰時多雲局部短暫雷陣雨 MOSTLY CLOUDY WITH LOCAL THUNDERSHOWERS 34
    # 陰時多雲局部雷陣雨 MOSTLY CLOUDY WITH LOCAL THUNDERSHOWERS 34
    # 多雲有陣雨或雷雨有霧 PARTLY CLOUDY WITH SHOWERS OR THUNDERSTORMS AND FOG 35
    # 多雲有雷陣雨有霧 PARTLY CLOUDY WITH THUNDERSHOWERS AND FOG 35
    # 多雲有霧有陣雨或雷雨 PARTLY CLOUDY WITH FOG AND SHOWERS OR THUNDERSTORMS 35
    # 多雲有霧有雷陣雨 PARTLY CLOUDY WITH FOG AND THUNDERSHOWERS 35
    # 多雲局部陣雨或雷雨有霧 PARTLY CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS AND FOG 35
    # 多雲局部短暫陣雨或雷雨有霧 PARTLY CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS AND FOG 35
    # 多雲局部短暫雷陣雨有霧 PARTLY CLOUDY WITH LOCAL THUNDERSTORMS AND FOG 35
    # 多雲局部雷陣雨有霧 PARTLY CLOUDY WITH LOCAL THUNDERSTORMS AND FOG 35
    # 多雲陣雨或雷雨有霧 PARTLY CLOUDY WITH SHOWERS OR THUNDERSTORMS AND FOG 35
    # 多雲短暫陣雨或雷雨有霧 PARTLY CLOUDY WITH OCCASIONAL SHOWERS OR THUNDERSTORMS AND FOG 35
    # 多雲短暫雷陣雨有霧 PARTLY CLOUDY WITH OCCASIONAL THUNDERSTORMS AND FOG 35
    # 多雲雷陣雨有霧 PARTLY CLOUDY WITH THUNDERSHOWERS AND FOG 35
    # 多雲時晴短暫陣雨或雷雨有霧 PARTLY CLEAR OCCASIONAL SHOWERS OR THUNDERSTORMS WITH FOG 35
    # 多雲時陰有陣雨或雷雨有霧 MOSTLY CLOUDY WITH SHOWERS OR THUNDERSTORMS AND FOG 36
    # 多雲時陰有雷陣雨有霧 MOSTLY CLOUDY WITH THUNDERSHOWERS AND FOG 36
    # 多雲時陰有霧有陣雨或雷雨 MOSTLY CLOUDY WITH FOG AND SHOWERS OR THUNDERSTORMS 36
    # 多雲時陰有霧有雷陣雨 MOSTLY CLOUDY WITH FOG AND THUNDERSHOWERS 36
    # 多雲時陰局部陣雨或雷雨有霧 MOSTLY CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS AND FOG 36
    # 多雲時陰局部短暫陣雨或雷雨有霧 MOSTLY CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS AND FOG 36
    # 多雲時陰局部短暫雷陣雨有霧MOSTLY CLOUDY WITH LOCAL THUNDERSTORMS AND FOG 36
    # 多雲時陰局部雷陣雨有霧 MOSTLY CLOUDY WITH LOCAL THUNDERSTORMS AND FOG 36
    # 多雲時陰陣雨或雷雨有霧 MOSTLY CLOUDY WITH SHOWERS OR THUNDERSTORMS AND FOG 36
    # 多雲時陰短暫陣雨或雷雨有霧 MOSTLY CLOUDY WITH OCCASIONAL SHOWERS OR THUNDERSTORMS AND FOG 36
    # 多雲時陰短暫雷陣雨有霧 MOSTLY CLOUDY WITH OCCASIONAL THUNDERSTORMS AND FOG 36
    # 多雲時陰雷陣雨有霧 MOSTLY CLOUDY WITH THUNDERSHOWERS AND FOG 36
    # 陰局部陣雨或雷雨有霧 CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS AND FOG 36
    # 陰局部短暫陣雨或雷雨有霧 CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS AND FOG 36
    # 陰局部短暫雷陣雨有霧 CLOUDY WITH LOCAL THUNDERSHOWERS AND FOG 36
    # 陰局部雷陣雨有霧 CLOUDY WITH LOCAL THUNDERSHOWERS AND FOG 36
    # 陰時多雲有陣雨或雷雨有霧 MOSTLY CLOUDY WITH SHOWERS OR THUNDERSTORMS AND FOG 36
    # 陰時多雲有雷陣雨有霧 MOSTLY CLOUDY WITH THUNDERSHOWERS AND FOG 36
    # 陰時多雲有霧有陣雨或雷雨 MOSTLY CLOUDY WITH FOG AND SHOWERS OR THUNDERSTORMS 36
    # 陰時多雲有霧有雷陣雨 MOSTLY CLOUDY WITH FOG AND THUNDERSHOWERS 36
    # 陰時多雲局部陣雨或雷雨有霧 MOSTLY CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS AND FOG 36
    # 陰時多雲局部短暫陣雨或雷雨有霧 MOSTLY CLOUDY WITH LOCAL SHOWERS OR THUNDERSTORMS AND FOG 36
    # 陰時多雲局部短暫雷陣雨有霧 MOSTLY CLOUDY WITH LOCAL THUNDERSHOWERS AND FOG 36
    # 陰時多雲局部雷陣雨有霧 MOSTLY CLOUDY WITH LOCAL THUNDERSHOWERS AND FOG 36
    # 陰時多雲陣雨或雷雨有霧 MOSTLY CLOUDY WITH SHOWERS OR THUNDERSTORMS AND FOG 36
    # 陰時多雲短暫陣雨或雷雨有霧 MOSTLY CLOUDY WITH OCCASIONAL SHOWERS OR THUNDERSTORMS AND FOG 36
    # 陰時多雲短暫雷陣雨有霧 MOSTLY CLOUDY WITH OCCASIONAL THUNDERSHOWERS AND FOG 36
    # 陰時多雲雷陣雨有霧 MOSTLY CLOUDY WITH THUNDERSHOWERS AND FOG 36
    # 陰短暫陣雨或雷雨有霧 CLOUDY WITH OCCASIONAL SHOWERS OR THUNDERSTORMS AND FOG 36
    # 陰短暫雷陣雨有霧 CLOUDY WITH OCCASIONAL THUNDERSHOWERS AND FOG 36
    # 雷陣雨有霧 THUNDERSHOWERS WITH FOG 36
    # 多雲局部雨或雪有霧 PARTLY CLOUDY WITH LOCAL RAIN OR SNOW AND FOG 37
    # 多雲時陰局部雨或雪有霧 MOSTLY CLOUDY WITH LOCAL RAIN OR SNOW AND FOG 37
    # 陰時多雲局部雨或雪有霧 MOSTLY CLOUDY WITH LOCAL RAIN OR SNOW AND FOG 37
    # 陰局部雨或雪有霧 CLOUDY WITH LOCAL RAIN OR SNOW AND FOG 37
    # 短暫雨或雪有霧 OCCASIONAL WITH RAIN OR SNOW AND FOG 37
    # 有雨或雪有霧 RAIN OR SNOW WITH FOG 37
    # 短暫陣雨有霧 OCCASIONAL SHOWERS WITH FOG 38
    # 短暫陣雨晨霧 OCCASIONAL SHOWERS AND MORNING FOG 38
    # 短暫雨有霧 OCCASIONAL RAIN WITH FOG 38
    # 短暫雨晨霧 OCCASIONAL RAIN WITH MORNING FOG 38
    # 有雨有霧 RAIN WITH FOG 39
    # 陣雨有霧 SHOWERS WITH FOG 39
    # 短暫陣雨或雷雨有霧 OCCASIONAL SHOWERS OR THUNDERSTORMS WITH FOG 41
    # 陣雨或雷雨有霧 SHOWERS OR THUNDERSTORMS WITH FOG 41
    # 下雪 SNOW 42
    # 積冰 ICE 42
    # 暴風雪 SNOW FLURRIES 42

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
