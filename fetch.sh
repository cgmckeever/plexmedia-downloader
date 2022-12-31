#!/bin/bash

source config.sh

IFSO=$IFS
IFS=$'\n'

open .

source env/bin/activate
for url in $LIST
do
    echo "Fetching ${url: -20}"
    python3 main.py -u ${PLEXUSER} -p ${PLEXPASS} $url
done
deactivate

IFS=$IFSO
