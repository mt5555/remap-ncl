#!/bin/bash
#
#  NCO based replacement for cube-to-target
#
#  Step 0:
#      use TR or mbtr to create cube3000 -> target_np4 and target_pg2 mapping files
#      this can take days for cube12000
#  Step 1:
#      use this script to interpolate cube3000 to target GLL grid
#      (just runs ncremap on terr, and then ncap2 to add PHIS=terr*g)
#  Step 2
#    apply dycore specific smoothing to PHIS in nctopo_nosmoothing.nc, using homme_tool
#    this will create nctopo_smoothed.nc file with smoothed PHIS and PHIS_d
#  Step 3
#    run this script to compute SGH and SGH30 associated with PHIS
#    
#  Uses ncremap and ncap2 since ncremap is about 3x faster than applying a mapfile via 
#  python/scipy sparse matrix multiply
#
#
wdir=~/scratch1/topo


args=("$@")
if [ "$#" -lt "3" ]; then
    echo
    echo "generate unsmoothed topo:"
    echo "./cube_to_target.sh  mapfile_GLL.nc USGS-topo-cube3000.nc  nctopo_nosmoothing.nc"
    echo 
    echo "compute SGH and add SGH and SGH30 to a smoothed topo file"
    echo "./cube_to_target.sh  mapfile_PG2.nc USGS-topo-cub3000.nc  nctopo_nosmoothing.nc nctopo_smoothed"
    echo
    exit 1
fi

grav=9.80616d0   # values used by CAM cube_to_target

cd $wdir
mapfile=$1
cube3000=$2
topotarg=$3

# STEP1: unsmoothed topo
if [ "$#" -eq "3" ]; then
  echo "Running step1: computing unsmoothed topo data on target grid"
  ncremap -m $mapfile  -v terr,terr_sq  $cube3000 $topotarg
  ncap2 -A -s 'PHIS=terr*$grav'  $toposmooth $toposmooth
fi


# STEP3: compute SGH for smoothed topo
# smoothed topo from homme_tool, will have PHIS (pg2 grid)  and PHIS_d (gll grid)
if [ "$#" -eq "4" ]; then
  toposmooth=$4

  #  check if terr_sq is in the file
  if ! ncdump -h $cube3000 | grep terr_sq ; then
    echo ERROR: variable terr_sq not in source data. You can add it via:
    echo Add terr_sq with correct units via:
    echo ncap2 -A -s 'terr_sq=terr*terr' $cube3000 $cube3000
    echo ncatted -O -v terr_sq -a units,,m,c,"m^2" $cube3000
    exit 1
  fi

  # compute SGH = REMAP(terr^2) - terr^2  on PG2 grid
  ncremap -m $mapfile  -v terr_sq,SGH30  $cube3000 temppg2.nc    # create file with terr_sq
  ncap2 -A -s 'terr=PHIS/$grav'  $toposmooth temppg2.nc    # add terr
  ncap2 -A -s 'SGH=terr_sq-terr*terr'  temppg2.nc          # compute and add SGH


  ncks -A -v SGH,SGH30,lat,lon temppg2.nc $toposmooth

  # add GLL coordinates for convience
  ncks -O -v lat,lon,ncol $topotarg temp.nc
  ncrename -v lat,lat_d -v lon,lon_d -d ncol,ncol_d temp.nc
  ncks -A -v lat_d,lon_d temp.nc  $toposmooth

  rm -f temp.nc temppg2.nc
fi
