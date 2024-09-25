#!/bin/bash

# ### #
# ENV #
# ### #
# see: 00_env.sh
if [ -n "$ZSH_VERSION" ]; then ME="${0:A}"; else ME=$(realpath ${BASH_SOURCE:0}); fi
export SCRIPT_BASE=${SCRIPT_BASE:-$(dirname $ME)}
source "$SCRIPT_BASE/00_env.sh"

export post_obsid=${post_obsid:-1286130104}
mkdir -p ${outdir}/${post_obsid}/post_im/
export post_obsim="${post_obsim:-${outdir}/${post_obsid}/post_im/${post_obsid}_deep-MFS-image-pb}"

# check for calibrated measurement set from previous step
# export cal_ms="${cal_ms:-${outdir}/${obsid}/cal/hyp_cal_${obsid}.ms}"
export obs_im="${obs_im:-${outdir}/${post_obsid}/img/${post_obsid}_deep-MFS-image-pb}"
echo $obs_im
set -e

if [ ! -f "${post_obsim}.fits" ];
then 
    echo "There's no image in the post image directory checking in img and running img again if needed." 
    if [ ! -f "${obs_im}.fits" ];
    then 
        echo "No image, rerunning img script" 
        $SCRIPT_BASE/07_img.sh
    fi 
    cp ${obs_im}.fits ${outdir}/${post_obsid}/post_im/
fi 


# if (($(ls -l $obs_im.fits | wc -l) < 1)); then
#     echo "obs_im=$obs_im does not exist. trying 07_img.sh"
#     $SCRIPT_BASE/07_img.sh
# fi


if [ ! -f "${post_obsim}_rms.fits" ]
then
    BANE --cores=1 --noclobber "${post_obsim}.fits"
    aegean --autoload --table "${post_obsim}.fits" "${post_obsim}.fits"> >(tee -a "${post_obsim}_aegean.log") 2> >(tee -a "${post_obsim}_aegean.log" >&2)
else
    aegean --autoload --table "${post_obsim}.fits" "${post_obsim}.fits"> >(tee -a "${post_obsim}_aegean.log") 2> >(tee -a "${post_obsim}_aegean.log" >&2)
fi 

nsrc=$(grep "INFO found" "${post_obsim}_aegean.log" | tail -1 | awk '{print $3}')

echo "Total sources found in image: ${nsrc}"
if [[ $nsrc -lt 250 ]]
then
    echo "Can't warp ${obsnum} -- only $nsrc sources and minimum required is 250 -- probably a horrible image"
else
