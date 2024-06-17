#!/bin/bash
#
# make SCRIP files for lat/lon grids
#
#
#
#
#
WDIR=~/scratch1/mapping/grids

args=("$@")
if [ "$#" -lt "1" ]; then
    echo "make-regRLL.sh  region-name"
    exit 1
fi
type=uni
name=$1



if [ $name = NA1 ]; then
  nlat=
  nlon=
  target=$WDIR/$name-${nlat}x${nlon}_SCRIP.nc
  ncremap -G ttl='Equi-Angular North Atlantic grid1 3km'#latlon=30,90#snwe=55.0,85.0,-90.0,0.0#lat_typ=uni#lon_typ=grn_ctr \
        -g $target
fi

