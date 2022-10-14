#!/bin/bash
#
#  makeVortex.sh shortname grid
#  Create .nc files with vortex, Y2_2 and Y16_32 analytic functions
#
#
exepath=~/codes/tempestremap/
wdir=~/scratch1/mapping

# maps needed:
./makeFVtoFV_esmf.sh bilin \
     ne30pg2  TEMPEST_ne30pg2.scrip.nc \
     oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc 
./makeFVtoFV_esmf.sh bilin \
      oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc \
      ne30pg2  TEMPEST_ne30pg2.scrip.nc 

./makeFVtoFV.sh bilin \
     ne30pg2  TEMPEST_ne30pg2.scrip.nc \
     oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc  
./makeFVtoFV.sh bilin \
      oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc \
      ne30pg2  TEMPEST_ne30pg2.scrip.nc 

./makeFVtoFV.sh intbilingb \
     ne30pg2  TEMPEST_ne30pg2.scrip.nc \
     oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc 
./makeFVtoFV.sh intbilingb \
      oEC60to30v3 ocean.oEC60to30v3.scrip.181106.nc \
      ne30pg2  TEMPEST_ne30pg2.scrip.nc 

               

name1=ne30pg2
grid1=TEMPEST_ne30pg2.g

#name2=ne1024pg2
name2=oEC60to30v3
grid2=ocean.oEC60to30v3.scrip.181106.nc

map=$wdir/maps/map_${name1}_to_${name2}_intbilin.nc
if [ ! -f $map ]; then
    echo missing map: $map
    exit 1
fi


./make_testdata.sh $name1   $grid1
./make_testdata.sh $name2   $grid2

# ncreamp + referror.py: 2min
ncremap -5 -m $map  \
        $wdir/testdata/${name1}_testdata.nc \
        $wdir/testdata/${name2}_mapped.nc

./referror.py vortex $wdir/testdata/${name2}_testdata.nc  $wdir/testdata/${name2}_mapped.nc
#./referror.py Y2_2   $wdir/testdata/${name2}_testdata.nc  $wdir/testdata/${name2}_mapped.nc
#./referror.py Y16_32 $wdir/testdata/${name2}_testdata.nc  $wdir/testdata/${name2}_mapped.nc 

# slow: 24min
# python script to apply map file directly
# doesn't integrate analytic solution over FV cells, errors 2x larger
./vortex.py $map


