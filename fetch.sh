#!/bin/bash

source config.sh

HERE=$(cd "$(dirname "$0")" && pwd)

LOG="$HERE/downloaded.log"
LOG_DAYS=30

# Log format: <epoch>\t<YYYY-MM-DD HH:MM>\t<url-key>
# Purge entries older than LOG_DAYS.
touch "$LOG"
cutoff=$(( $(date +%s) - LOG_DAYS * 86400 ))
awk -F'\t' -v c="$cutoff" '$1 >= c' "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"

# Same item can be linked with a different &context=..., so key on the url without it.
url_key() { echo "${1%%&context=*}"; }

IFSO=$IFS
IFS=$'\n'

open .

# fetch <dest-dir> <newline-separated url list>
fetch() {
    local dest="$HERE/$1"
    local urls="$2"
    mkdir -p "$dest"
    (
        cd "$dest" || exit 1
        for url in $urls
        do
            key=$(url_key "$url")
            prev=$(awk -F'\t' -v k="$key" '$3 == k { d = $2 } END { print d }' "$LOG")
            if [ -n "$prev" ]
            then
                read -r -p "Already downloaded ${url: -40} ($prev), re-download (y/N)? " ans < /dev/tty
                [[ "$ans" =~ ^[Yy]$ ]] || { echo "Skipping"; continue; }
            fi

            echo "Fetching ${url: -40} -> $1"
            # main.py prints one "DIR:<folder>" line for the top-level folder it created.
            # It has fully exited by the time we read this, so nothing is writing to
            # that folder and we can safely rename it before the next url.
            root=$(python3 "$HERE/main.py" -u ${PLEXUSER} -p ${PLEXPASS} $url | tee /dev/tty | grep '^DIR:' | cut -d: -f2-)
            echo $root
            new=${root// /-}
            if [ -n "$root" ] && [ "$root" != "$new" ]
            then
                if [ -d "$new" ]
                then
                    # Target already exists (e.g. another season of the same show): merge.
                    cp -R "$root"/. "$new"/ && rm -rf "$root"
                else
                    mv "$root" "$new"
                fi
                # The folder and the single file inside share the same name (movies); rename both.
                f=("$new/$root".*)
                [ -e "$f" ] && mv "$f" "$new/$new.${f##*.}"
            fi
            # Only log once main.py reported a completed download.
            [ -n "$root" ] && printf '%s\t%s\t%s\n' "$(date +%s)" "$(date '+%Y-%m-%d %H:%M')" "$key" >> "$LOG"
        done
    )
}

source env/bin/activate
fetch 1-movies "$MOVIES"
fetch 1-television "$TV"
deactivate

IFS=$IFSO
