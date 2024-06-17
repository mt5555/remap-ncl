#!/bin/bash
#
# make SCRIP files for lat/lon grids
#
# common nlons:
#
# 180, 256, 360, 400, 512, 720, 1024, 1440, 1600, 2048, 2880, 3200, 3584, 3840
#
#
#
#
WDIR=~/scratch1/mapping/grids

args=("$@")
if [ "$#" -lt "1" ]; then
    echo "makeRLL.sh  nlon  [cap,uni] [lon_est]"
    exit 1
fi
type="cap"
if [ "$#" -ge "2" ]; then
    type=$2
fi
wst=180.0  # lon default left edge is 180W
if [ "$#" -ge "3" ]; then
    wst=$3
fi


nlon=$1
nlat=$nlon
nlat=$(( nlon / 2 ))
if [ "$type" = cap ]; then
  (( nlat += 1 ))
  type=cap
else  
  type=uni
fi

if [ $wst ==  "180.0" ]; then
    target=$WDIR/${nlat}x${nlon}_SCRIP.nc
else
    target=$WDIR/${nlat}x${nlon}-${wst}W_SCRIP.nc
    # add option below:    \#lon_wst=${wst} 
    echo not yet coded
    exit 1
fi
if [ -f $target ]; then
    echo reusing: $target
    exit 0
fi
echo "RLL Mesh:  $target"


if [ "$type" = cap ]; then
    # cant figure out how to have spaces in the name, due to tcsh parsing:
    ncremap -G ttl="lat-lon-cap-grid"\#latlon=$nlat,$nlon\#lat_typ=fv\#lon_typ=grn_ctr \
        -g $target
else
    ncremap -G ttl="lat-lon-uni-grid"\#latlon=$nlat,$nlon\#lat_typ=uni\#lon_typ=grn_ctr \
        -g $target
fi

   
