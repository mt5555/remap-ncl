#!/bin/bash
#
#  makeVortex.sh shortname grid
#  Create .nc files with vortex, Y2_2 and Y16_32 analytic functions
#
#
exepath=~/codes/tempestremap/
wdir=~/scratch1/mapping
mkdir $wdir/grids
mkdir $wdir/maps


# maps needed:
./makeFVtoFV.sh bilin \
      oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc \
      ne30pg2  TEMPEST_ne30pg2.scrip.nc   || exit 1  
./makeFVtoFV.sh bilin \
     ne30pg2  TEMPEST_ne30pg2.scrip.nc \
     oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc  || exit 1  

./makeFVtoFV.sh intbilingb \
      oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc \
      ne30pg2  TEMPEST_ne30pg2.scrip.nc  # FAILS 2023/7, works 2024/6
./makeFVtoFV.sh intbilingb \
     ne30pg2  TEMPEST_ne30pg2.scrip.nc \
     oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc   || exit 1

./makeFVtoFV.sh intbilin \
      oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc \
      ne30pg2  TEMPEST_ne30pg2.scrip.nc     # FAILS 2023/7, works 2024/6
./makeFVtoFV.sh intbilin \
     ne30pg2  TEMPEST_ne30pg2.scrip.nc \
     oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc  || exit 1  


./makeFVtoFV.sh bilin_esmf \
      oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc \
      ne30pg2  TEMPEST_ne30pg2.scrip.nc             || exit 1
./makeFVtoFV.sh bilin_esmf \
     ne30pg2  TEMPEST_ne30pg2.scrip.nc \
     oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc  || exit 1

               
echo 
name1=ne30pg2
grid1=TEMPEST_ne30pg2.g

name2=oEC60to30v3
grid2=ocean.oEC60to30v3.scrip.181106.nc

# atm->ocn
#python ./vortex.py $wdir/maps/map_${name1}_to_${name2}_bilin.nc
#python ./vortex.py $wdir/maps/map_${name1}_to_${name2}_bilin_esmf.nc   
#python ./vortex.py $wdir/maps/map_${name1}_to_${name2}_intbilin.nc
#python ./vortex.py $wdir/maps/map_${name1}_to_${name2}_intbilingb.nc

# ocn->atm
python ./vortex.py $wdir/maps/map_${name2}_to_${name1}_bilin.nc
python ./vortex.py $wdir/maps/map_${name2}_to_${name1}_bilin_esmf.nc    
python ./vortex.py $wdir/maps/map_${name2}_to_${name1}_intbilin.nc
python ./vortex.py $wdir/maps/map_${name2}_to_${name1}_intbilingb.nc

# ESMF: errors are much better, but it does not map data two partial cells

