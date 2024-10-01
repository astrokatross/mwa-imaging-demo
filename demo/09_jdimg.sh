#!/bin/bash

# ### #
# ENV #
# ### #
# see: 00_env.sh
if [ -n "$ZSH_VERSION" ]; then ME="${0:A}"; else ME=$(realpath ${BASH_SOURCE:0}); fi
export SCRIPT_BASE=${SCRIPT_BASE:-$(dirname $ME)}
source "$SCRIPT_BASE/00_env.sh"

export obslist={obslist:-"1121334536 1303134032 1341914000"}

cal_mss=()
for obs in ${obslist[@]}
do
    echo $obs
    cal_mss+="${outdir}/${obs}/cal/hyp_cal_${obs}.ms"
done

set -e
for cal_ms in ${cal_mss[@]}
do
    if (($(ls -ld $cal_ms | wc -l) < 1)); then
        echo "cal_ms=$cal_ms does not exist. trying 06_cal.sh"
        $SCRIPT_BASE/06_cal.sh
    fi
done 

export briggs=${briggs:-0}
export scale=${scale:-"20asec"}
export mgain=${mgain:-0.85}
export mscale=${mscale:-0.6}
export size=${size:-2048}
export gain=${gain:-0.1}

cores=$(nproc --all)
export cpus=${cpus:-cores}


export taper=${taper:-}
export multiscale=${multiscale:-}

if [[ -n $multiscale ]];
then 
    multiscale="-multiscale -multiscale-scale-bias=${mscale}"
fi 

mkdir -p "${outdir}/comb_img/"
export imname=${imname:-"jointdeconv"}
export imgname="${outdir}/combined/img/${imname}"

# wsclean needs to know the directory of the beam file
export beam_path="${MWA_BEAM_FILE%/*}"
[[ $beam_path =~ / ]] || export beam_path="${PWD}"

# set idg_mode to "cpu" or "hybrid" based from gpus
export idg_mode="cpu"
if [[ -n "${gpus:-}" ]]; then
    export idg_mode="hybrid"
fi


if [ ! -f "${imgname}-image-pb.fits" ]; then
    wsclean \
        -name "${imgname}" \
        -size ${size} ${size} \
        -j $cpus \
        -scale ${scale} \
        -pol I \
        -nmiter 2 \
        -niter 10000 \
        -mgain ${mgain} \
        -gridder idg -grid-with-beam -idg-mode $idg_mode \
        -weight briggs ${briggs} \
        ${multiscale} ${taper} \
        -gain ${gain} \
        -auto-threshold 1 -auto-mask 3 \
        -make-psf \
        -mwa-path "$beam_path" \
        -temp-dir /tmp \
        $cal_mss
else
    echo "${imgname}-image-pb.fits exists, skipping wsclean"
fi


