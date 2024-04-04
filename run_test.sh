#! /usr/bin/env bash

# TODO: Remove me

nextflow run barebones.nf \
    -resume \
    -ansi-log false \
    -profile test,singularity \
    -dump-channels \
    --outdir results \
    --db_cache 'results/database_cache' \
    --validate_params false