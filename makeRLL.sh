#!/bin/tcsh
# nlons:
#
# 180, 256, 360, 400, 512, 720, 1024, 1440, 1600, 2048, 2880
# 3200, 3584, 3840
#
#
set WDIR = ~/scratch1/mapping

set nlon=8192
set nlat = $nlon
@ nlat /= 2
if ( 1 ) then
  @ nlat += 1 
  set type = cap
  set rlltype = --global_cap
else  
  set type = uni
  set rlltype =
endif

echo "RLL Mesh"
set target = $WDIR/${nlat}x${nlon}_SCRIP.nc

if ( $rlltype == '--global_cap') then
   set echo
    # cant figure out how to have spaces in the name, due to tcsh parsing:
    ncremap -G ttl="lat-lon-cap-grid"\#latlon=$nlat,$nlon\#lat_typ=fv\#lon_typ=grn_ctr \
        -g $target
else
    ncremap -G ttl="lat-lon-uni-grid"\#latlon=$nlat,$nlon\#lat_typ=uni\#lon_typ=grn_ctr \
        -g $target
endif

   
