#!/usr/bin/env bash
set -uo pipefail

URL="https://worldcup26.ir/get/games"
GAME_ID="679c9c8a5749c4077500e024"
REFRESH=2

GRAY=$(tput dim || true)
GREEN=$(tput setaf 2 || true)
CYAN=$(tput setaf 6 || true)
RESET=$(tput sgr0 || true)

cleanup() {
    tput cnorm
    tput rmcup 2>/dev/null
    tput sgr0
}
trap cleanup EXIT
trap 'exit 130' INT TERM

tput smcup
tput civis

extract() {
    echo -n "$1" | awk -v t="$2" '
  function field(rec, key,   s) {
    if (match(rec, "\"" key "\":\"[^\"]*\"")) {
      s = substr(rec, RSTART, RLENGTH)
      sub("\"" key "\":\"", "", s); sub("\"$", "", s)
      return s
    }
    return ""
  }
  {
    n = split($0, recs, "},{")
    for (i = 1; i <= n; i++) {
      if (index(recs[i], "\"_id\":\"" t "\"")) {
        home = field(recs[i], "home_team_name_en"); if (home == "") home = field(recs[i], "home_team_label")
        away = field(recs[i], "away_team_name_en"); if (away == "") away = field(recs[i], "away_team_label")
        printf "%s\t%s\t%s\t%s\t%s\t%s - %s\t%s\n",
          field(recs[i],"id"), field(recs[i],"group"), field(recs[i],"time_elapsed"),
          home, away, field(recs[i],"home_score"), field(recs[i],"away_score"), field(recs[i],"local_date")
        break
      }
    }
  }'
}

center() {
    local plain="$1" pretty="${2:-$1}" offset="${3:-0}" w len pad
    w=$(tput cols)
    len=${#plain}
    pad=$(((w - len) / 2 + offset))
    ((pad < 0)) && pad=0
    ((pad < 0)) && pad=0
    printf '%*s%s
' "$pad" '' "$pretty"
}

center_matchup() {
    local home="$1" away="$2" half lpad
    half=$(($(tput cols) / 2))
    lpad=$((half - ${#home} - 8))
    ((lpad < 0)) && lpad=0
    printf '%*s%s   %s   %s\n' "$lpad" '' \
        "${CYAN}${home}${RESET}    " "${GRAY}|${RESET}" "    ${CYAN}${away}${RESET}"
}

draw() {
    local rows mid
    rows=$(tput lines)
    mid=$((rows / 2 - 8))
    ((mid < 0)) && mid=0

    tput cup 0 0
    tput ed
    for ((i = 0; i < mid; i++)); do echo; done

    center "$status" "${GRAY}${status}${RESET}"
    echo
    center_matchup "$home" "$away"
    echo
    center "$score" "${GREEN}${score}${RESET}" -1
    echo
    echo
    center "Ctrl+C to quit" "${GRAY}Ctrl+C to quit${RESET}"
}

while true; do
    data=$(curl -fsS "$URL") || {
        cleanup
        echo "fetch failed" >&2
        exit 1
    }

    IFS=$'\t' read -r _ _ status home away score _ < <(extract "$data" "$GAME_ID")

    draw
    sleep "$REFRESH"
done
