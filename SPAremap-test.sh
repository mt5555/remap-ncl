#!/bin/bash
#
#  makeVortex.sh shortname grid
#  Create .nc files with vortex, Y2_2 and Y16_32 analytic functions
#
#
exepath=~/codes/tempestremap/
wdir=~/scratch1/mapping

name1=ne30np4
grid1=TEMPEST_ne30.g

name2=ne1024pg2
#name2=ne30pg2
grid2=TEMPEST_${name2}.g
map=$wdir/maps/map_${name1}_to_${name2}_intbilin.nc
if [ ! -f $map ]; then
    echo missing map: $map
    exit 1
fi


./make_testdata.sh $name1   $grid1
./make_testdata.sh $name2   $grid2

ncremap -5 -m $map  \
        $wdir/testdata/${name1}_testdata.nc \
        $wdir/testdata/${name2}_mapped.nc

./referror.py $wdir/testdata/${name2}_testdata.nc  $wdir/testdata/${name2}_mapped.nc

# python script to apply map file directly
# doesn't integrate analytic solution over FV cells, errors 2x larger
./vortex.py $map

