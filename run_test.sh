#! /usr/bin/env bash

# TODO: Remove me

nextflow run main.nf \
    -resume \
    -ansi-log false \
    -profile test,singularity \
    -dump-channels \
    --outdir results \
    --db_cache 'work/database_cache' \
    --validate_params false
