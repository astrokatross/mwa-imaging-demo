#!/bin/bash

# ### #
# ENV #
# ### #
# see: 00_env.sh
if [ -n "$ZSH_VERSION" ]; then ME="${0:A}"; else ME=$(realpath ${BASH_SOURCE:0}); fi
export SCRIPT_BASE=${SCRIPT_BASE:-$(dirname $ME)}
source "$SCRIPT_BASE/00_env.sh"

export obsid=${obsid:-1341914000}

# check for calibrated measurement set from previous step
# export cal_ms="${cal_ms:-${outdir}/${obsid}/cal/hyp_cal_${obsid}.ms}"
export obs_im="${obs_im:-${outdir}/${obsid}/img/wsclean_hyp_${obsid}_deep-MFS-image-pb.fits}"

set -e
if (($(ls -l $obs_im | wc -l) < 1)); then
    echo "obs_im=$obs_im does not exist. trying 07_img.sh"
    $SCRIPT_BASE/07_img.sh
fi

