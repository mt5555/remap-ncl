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

#name2=ne1024pg2
name2=ne30pg2
grid2=TEMPEST_${name2}.g
map=$wdir/maps/map_${name1}_to_${name2}_intbilin.nc
#map=$wdir/maps/map_ne30np4_to_ne1024pg2_nco_aave.c20220910.nc
if [ ! -f $map ]; then
    echo missing map: $map
    exit 1
fi

################################################################
# compute error directly from map file
###############################################################
echo ====== computing cell center pointwise error:
./vortex.py $map


################################################################
# make testdata, ncreamp, referror.py and plot
###############################################################
echo 
echo ===== computing cell integrated error:
./make_testdata.sh $name1   $grid1
./make_testdata.sh $name2   $grid2

ncremap -5 -m $map  \
        $wdir/testdata/${name1}_testdata.nc \
        $wdir/testdata/${name2}_mapped.nc

./referror.py vortex $wdir/testdata/${name2}_testdata.nc  $wdir/testdata/${name2}_mapped.nc
#./referror.py Y2_2   $wdir/testdata/${name2}_testdata.nc  $wdir/testdata/${name2}_mapped.nc
#./referror.py Y16_32 $wdir/testdata/${name2}_testdata.nc  $wdir/testdata/${name2}_mapped.nc 


exit 0
################################################################
# make a plot of the mapped data
###############################################################
~/codes/nclscript/contour/contour.py \
    -i $wdir/testdata/${name2}_mapped.nc \
   -y mpl -r 4096x8192 -m europe -c 5 vortex
