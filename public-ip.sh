#!/bin/bash
# public-ip.sh - fetch the public IP from one of those whatismyip services.

PROVIDERS='
https://api.ipify.org
http://ipecho.net/plain
http://icanhazip.com
http://wtfismyip.com/text
http://whatismyip.akamai.com
https://4.ifcfg.me
http://ip.tyk.nu
http://ifcfg.me
http://l2.io/ip
http://ident.me
http://ipof.in/txt
http://ip.appspot.com
http://curlmyip.com
http://wgetip.com
http://bot.whatismyipaddress.com
http://eth0.me'

echo 'Fetching Public IP Address..' >&2;

{
        # shuffle the seeds list
        echo -n | sort -R 2>/dev/null && {
                # use sort -R
                echo "${PROVIDERS}" | sort -R
        } || {
                # sort -R not universally supported - use a fallback mechanism (prepend a random number to each line)
                echo "${PROVIDERS}" | while read provider
                do
                        rand_num="${RANDOM}"                                                    # use $RANDOM (NB: not all shells have $RANDOM)
                        [[ -z "${rand_num}" ]] && rand_num=$(od -An -N2 -i /dev/urandom)        # use /dev/urandom (NB: containers might not see /dev)
                        [[ -z "${rand_num}" ]] && rand_num=$(date '+%N')                        # use current time in nanoseconds (NB: not all dates support %N)
                        [[ -z "${rand_num}" ]] && rand_num=1                                    # give up (dont shuffle)
                        echo -e "${rand_num}\t${provider}"
                done | sort -n | sed 's/^[0-9\t]*//'
        }
} | {
        padding=$(echo "${PROVIDERS}" | wc -L | tr -d '\n')
        while read provider
        do
                [[ -z "${provider}" ]] && continue;
                printf '\tTrying \033[0;37m%-'"${padding}"'s \033[0m' "${provider}" >&2
                export IP_ADDRESS="$(curl --connect-timeout 2 ${provider} 2>/dev/null)"
                export IP_ADDRESS=$(echo "$IP_ADDRESS" | grep -Eo '[12]?[0-9][0-9]?[.][12]?[0-9][0-9]?[.][12]?[0-9][0-9]?[.][12]?[0-9][0-9]?' | head -1)
                [[ -z "${IP_ADDRESS}" ]] && {
                        echo -e '\033[1;31mNope.\033[0m' >&2
                        continue;
                } || {
                        echo -e '\033[1;32mSuccess!\033[0m' >&2
                        echo -e 'Found IP Address \033[1;37m'"$IP_ADDRESS"'\033[0m' >&2
                        echo "${IP_ADDRESS}"
                        break;
                }
        done
} | grep . && {
        # some shells do weird things with exit in subshells - so this catches that
        exit 0
} || {
        # loop fell through - no ip found.
        echo -e '\033[1;31mNo Public IP address found!\033[0m' >&2
        exit 1
