#!/bin/bash

source config.sh

HERE=$(cd "$(dirname "$0")" && pwd)

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
        done
    )
}

source env/bin/activate
fetch 1-movies "$MOVIES"
fetch 1-television "$TV"
deactivate

IFS=$IFSO
