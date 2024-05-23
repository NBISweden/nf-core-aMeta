#! /usr/bin/env bash

# TODO: Move to NBIS project

AMETA_OUTPUT=checklist_ameta.chk
NFCORE_OUTPUT=checklist_nf-core.chk

while read -r MD5SUM FILEPATH; do
    FILE=$( basename "$FILEPATH" )
    DIR=$( dirname "$FILEPATH" )
    if grep -q -w "$DIR/.*$FILE" $NFCORE_OUTPUT; then
        if grep -q "^$MD5SUM  $DIR/.*$FILE$" $NFCORE_OUTPUT; then
            echo "PASS: $FILEPATH"
        else
            echo "MD5SUM: $FILEPATH"
        fi
    else
        echo "FAIL: $FILE not found in $DIR"
    fi
done < $AMETA_OUTPUT