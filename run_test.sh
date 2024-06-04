#! /usr/bin/env bash

# TODO: Remove me

nextflow run main.nf \
    -resume \
    -ansi-log false \
    -profile test,docker \
    -dump-channels \
    --outdir results \
    --db_cache 'work/database_cache'
