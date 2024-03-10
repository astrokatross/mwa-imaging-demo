#!/bin/bash
# use Birli to preprocess raw files
# details: https://github.com/MWATelescope/Birli/

# ### #
# ENV #
# ### #
# see: 00_env.sh
export SCRIPT_BASE=${SCRIPT_BASE:-${PWD}/demo/}
source $SCRIPT_BASE/00_env.sh

export obsid=${obsid:-1341914000}

# ### #
# RAW #
# ### #
# check for raw files
export raw_glob=${outdir}/${obsid}/raw/${obsid}_2\*.fits
if ! eval ls -1 $raw_glob >/dev/null; then
    echo "raw not present: $raw_glob , try ${SCRIPT_BASE}/02_download.sh"
    exit 1
fi
# check for metafits files
export metafits=${outdir}/${obsid}/raw/${obsid}.metafits
if [[ ! -f "$metafits" ]]; then
    echo "metafits not present, downloading $metafits"
    wget -O "$metafits" $'http://ws.mwatelescope.org/metadata/fits?obs_id='${obsid}
fi

# #### #
# PREP #
# #### #
# DEMO: preprocess raw files with birli
# Cotter only works on legacy correlator files and has been discontinued.

# uncomment to modify preprocessing settings
# export freqres_khz=10     # frequency resolution to average to in kHz
# export birli_args=""      # extra birli args if any
export timeres_s=8          # time resolution to average to in seconds
export edgewidth_khz=80     # edge width to flag on each coarse channel in kHz

mkdir -p ${outdir}/${obsid}/prep
export prep_uvfits="${outdir}/${obsid}/prep/birli_${obsid}.uvfits"
export prepqa="${prep_uvfits%%.uvfits}_qa.json"

set -eux
if [[ ! -f $prep_uvfits ]]; then
    eval $birli ${birli_args:-} \
        -m "${metafits}" \
        $( [[ -n "${edgewidth_khz:-}" ]] && echo "--flag-edge-width ${edgewidth_khz}" ) \
        $( [[ -n "${freqres_khz:-}" ]] && echo "--avg-freq-res ${freqres_khz}" ) \
        $( [[ -n "${timeres_s:-}" ]] && echo "--avg-time-res ${timeres_s}" ) \
        -u "${prep_uvfits}" \
        $raw_glob
fi

# ####### #
# PREP QA #
# ####### #
# DEMO: use mwa_qa for quality analysis of preprocessed uvfits
# details: https://github.com/d3v-null/mwa_qa (my fork of  https://github.com/Chuneeta/mwa_qa/ )

if [[ ! -f "$prepqa" ]]; then
    eval $run_prepqa $prep_uvfits $metafits --out $prepqa
fi

# DEMO: extract bad antennas from prepqa json with jq
# - both of the provided observations pass QA, so no bad antennas are reported
export prep_bad_ants=$(eval $jq -r $'\'.BAD_ANTS|join(" ")\'' $prepqa)

# DEMO: plot the prep qa results
# - RMS plot: RMS of all autocorrelation values for each antenna
# - zscore:
eval $plot_prepqa $prepqa --save --out ${prep_uvfits%%.uvfits}

echo $obsid $prep_bad_ants