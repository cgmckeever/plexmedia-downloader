#!/bin/bash

source config.sh

IFSO=$IFS
IFS=$'\n'

open .

source env/bin/activate
for url in $LIST
do
    echo "Fetching ${url: -20}"
    # main.py prints one "DIR:<folder>" line for the top-level folder it created.
    # It has fully exited by the time we read this, so nothing is writing to
    # that folder and we can safely rename it before the next url.
    root=$(python3 main.py -u ${PLEXUSER} -p ${PLEXPASS} $url | tee /dev/tty | grep '^DIR:' | cut -d: -f2-)
    echo $root
    new=${root// /-}
    if [ -n "$root" ] && [ "$root" != "$new" ]
    then
        # The folder and the single file inside share the same name; rename both.
        mv "$root" "$new"
        f=("$new/$root".*)
        [ -e "$f" ] && mv "$f" "$new/$new.${f##*.}"
    fi
done
deactivate

IFS=$IFSO
