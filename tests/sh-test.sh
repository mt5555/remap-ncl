#!/bin/bash
#
#  map ne120pg2 -> ne3pg2
#  show aliasing errors with bilinear maps
#  using Y16_32
#
exepath=~/codes/tempestremap/
wdir=~/scratch1/mapping

#mapalg=bilin_esmf
#mapalg=intbilin
#mapalg=bilin
mapalg=mono


./makeSE.sh 120
name1=ne120pg2
grid1=TEMPEST_ne120pg2.g
grid1s=TEMPEST_ne120pg2.scrip.nc


./makeSE.sh 3
name2=ne3pg2
grid2=TEMPEST_ne3pg2.g
grid2s=TEMPEST_ne3pg2.scrip.nc


./makeFVtoFV.sh $mapalg $name1 $grid1s $name2  $grid2s  || exit 1
map=$wdir/maps/map_${name1}_to_${name2}_${mapalg}.nc
if [ ! -f $map ]; then
    echo missing map: $map
    exit 1
fi

./make_testdata.sh $name1  $grid1
./make_testdata.sh $name2  $grid2

ncremap -5 -m $map  \
        $wdir/testdata/${name1}_testdata.nc \
        $wdir/testdata/${name2}_${mapalg}_mapped.nc

~/codes/nclscript/contour/contour.py \
    -i $wdir/testdata/${name2}_${mapalg}_mapped.nc \
    -r 128x256 \
    -c 1,3,.1  Y16_32


exit 0

# TR testdata files dont include coordinates so we cant plot directly
# crude workaround: map to lat/lon first
./makeFVtoFV.sh intbilin $name1 $grid1s 180x360 180x360_SCRIP.nc  || exit 1
map=$wdir/maps/map_${name1}_to_180x360_intbilin.nc
ncremap -5 -m $map  \
        $wdir/testdata/${name1}_testdata.nc \
        $wdir/testdata/180x360_testdata.nc

~/codes/nclscript/contour/contour.py \
    -i $wdir/testdata/180x360_testdata.nc  \
    -c 1,3,.1  Y16_32

