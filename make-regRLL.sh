#!/bin/bash
#
# Use ncremap to make SCRIP files for regional lat/lon grids
#
# ./make-regRLL.sh region_name
#
# region names so far:
#  NA1  0.03 degree (3.4km at Equator) over north atlantic
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

#1deg = 113km
#0.03 deg =  3.4km
#0.025 deg = 2.8km

if [ $name = NA1 ]; then
    # 10x reduced, for plotting
    nlat=80   # 24/.03=800
    nlon=100  # 30/.03=1000
    target=$WDIR/$name-${nlat}x${nlon}_SCRIP.nc
    echo $target
    ncremap  -g $target -G \
       ttl='Equi-Angular North Atlantic grid1 3km'#latlon=$nlat,$nlon#snwe=22.0,46.0,-80.0,-50.0#lat_typ=uni#lon_typ=grn_ctr 
    python plotscrip.py $target NA1

    nlat=800   # 24/.03=800
    nlon=1000  # 30/.03=1000
    target=$WDIR/$name-${nlat}x${nlon}_SCRIP.nc
    echo $target
    ncremap  -g $target -G \
      ttl='Equi-Angular North Atlantic grid1 3km'#latlon=$nlat,$nlon#snwe=22.0,46.0,-80.0,-50.0#lat_typ=uni#lon_typ=grn_ctr 

fi



