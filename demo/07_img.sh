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
export cal_ms="${cal_ms:-${outdir}/${obsid}/cal/hyp_cal_${obsid}.ms}"

set -e
if (($(ls -ld $cal_ms | wc -l) < 1)); then
    echo "cal_ms=$cal_ms does not exist. trying 06_cal.sh"
    $SCRIPT_BASE/06_cal.sh
fi

# ### #
# IMG #
# ### #
mkdir -p "${outdir}/${obsid}/img"

# wsclean needs to know the directory of the beam file
export beam_path="${MWA_BEAM_FILE%/*}"
[[ $beam_path =~ / ]] || export beam_path="${PWD}"

# set idg_mode to "cpu" or "hybrid" based from gpus
export idg_mode="cpu"
if [[ -n "${gpus:-}" ]]; then
    export idg_mode="hybrid"
fi

export imgname="${outdir}/${obsid}/img/wsclean_hyp_${obsid}"
# if [ ! -f "${imgname}-image.fits" ]; then
wsclean \
    -name "${imgname}_gx2" \
    -size 8000 8000 \
    -j 16 \
    -scale 15asec \
    -pol I \
    -nmiter 2 \
    -niter 10000000 \
    -multiscale \
    -mgain 0.95 \
    -multiscale-gain 0.15 \
    -multiscale-scale-bias 0.6 \
    -gridder idg -grid-with-beam -idg-mode $idg_mode \
    -weight briggs 1 \
    -join-channels \
    -channels-out 4 \
    -fit-spectral-pol 2 \
    -mgain 0.85 -gain 0.1 \
    -auto-threshold 1 -auto-mask 3 \
    -make-psf \
    -mwa-path "$beam_path" \
    -apply-primary-beam \
    -temp-dir /tmp \
    $cal_ms
# else
#     echo "${imgname}-image.fits exists, skipping wsclean"
# fi
