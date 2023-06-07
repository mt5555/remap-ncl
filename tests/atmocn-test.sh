#!/bin/bash
#
#  makeVortex.sh shortname grid
#  Create .nc files with vortex, Y2_2 and Y16_32 analytic functions
#
#
exepath=~/codes/tempestremap/
wdir=~/scratch1/mapping

# maps needed:
./makeFVtoFV.sh bilin_esmf \
      oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc \
      ne30pg2  TEMPEST_ne30pg2.scrip.nc             || exit 1
./makeFVtoFV.sh bilin_esmf \
     ne30pg2  TEMPEST_ne30pg2.scrip.nc \
     oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc  || exit 1

./makeFVtoFV.sh bilin \
      oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc \
      ne30pg2  TEMPEST_ne30pg2.scrip.nc           
./makeFVtoFV.sh bilin \
     ne30pg2  TEMPEST_ne30pg2.scrip.nc \
     oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc  || exit 1  

./makeFVtoFV.sh intbilin \
      oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc \
      ne30pg2  TEMPEST_ne30pg2.scrip.nc           
./makeFVtoFV.sh intbilin \
     ne30pg2  TEMPEST_ne30pg2.scrip.nc \
     oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc  || exit 1  

./makeFVtoFV.sh intbilingb \
      oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc \
      ne30pg2  TEMPEST_ne30pg2.scrip.nc           
./makeFVtoFV.sh intbilingb \
     ne30pg2  TEMPEST_ne30pg2.scrip.nc \
     oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc   || exit 1

               

name1=ne30pg2
grid1=TEMPEST_ne30pg2.g

name2=oEC60to30v3
grid2=ocean.oEC60to30v3.scrip.181106.nc


./vortex.py $wdir/maps/map_${name1}_to_${name2}_bilin.nc
./vortex.py $wdir/maps/map_${name1}_to_${name2}_bilin_esmf.nc
./vortex.py $wdir/maps/map_${name1}_to_${name2}_intbilin.nc
./vortex.py $wdir/maps/map_${name1}_to_${name2}_intbilingb.nc



exit


echo "===== generating test data for plots"
./make_testdata.sh $name1   $grid1
./make_testdata.sh $name2   $grid2

# ncreamp + referror.py: 2min
ncremap -5 -m $map  \
        $wdir/testdata/${name1}_testdata.nc \
        $wdir/testdata/${name2}_mapped.nc

./referror.py vortex $wdir/testdata/${name2}_testdata.nc  $wdir/testdata/${name2}_mapped.nc
#./referror.py Y2_2   $wdir/testdata/${name2}_testdata.nc  $wdir/testdata/${name2}_mapped.nc
#./referror.py Y16_32 $wdir/testdata/${name2}_testdata.nc  $wdir/testdata/${name2}_mapped.nc 




