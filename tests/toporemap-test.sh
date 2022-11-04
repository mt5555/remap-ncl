#!/bin/bash
#
#  map ne120 highres topo to low res RLL gridtest ne20np4 and ne30pg2 maps to lat/lon grids
#
#  used to llok at downsampling errors
#
#  bilin vs mono/intbilin
#  not a clear advantage between bilin and mono
#
#  what about Y16_32?
#
#
exepath=~/codes/tempestremap/
wdir=~/scratch1/mapping

mapalg=bilin_esmf
#mapalg=intbilin
#mapalg=bilin
#mapalg=mono

name1=ne120pg2
grid1=TEMPEST_ne120pg2.g
grid1s=TEMPEST_ne120pg2.scrip.nc

#name1=ne120np4
#grid1=TEMPEST_ne120.g
#grid1s=ne120np4_pentagons.100310.nc

./makeSE.sh 120
./makeRLL.sh  128 uni
rll1=64x128


if [[ $name1 == *"np4"* ]]; then
    var=PHIS_d
    if [ "$mapalg" == "bilin_esmf" ] ; then
        ./makeFVtoFV_esmf.sh bilin $name1 $grid1s $rll1  ${rll1}_SCRIP.nc  || exit 1
    else
        ./makeSEtoFV.sh $mapalg $name1 $grid1 $rll1  ${rll1}_SCRIP.nc  || exit 1
    fi
else
    if [ "$mapalg" == "bilin_esmf" ] ; then
        ./makeFVtoFV_esmf.sh bilin $name1 $grid1s $rll1  ${rll1}_SCRIP.nc  || exit 1
    else
        ./makeFVtoFV.sh $mapalg $name1 $grid1 $rll1  ${rll1}_SCRIP.nc  || exit 1
    fi
    var=PHIS
fi

map=$wdir/maps/map_${name1}_to_${rll1}_${mapalg}.nc
if [ ! -f $map ]; then
    echo missing map: $map
    exit 1
fi


#./make_testdata.sh $name1   $grid1
#./make_testdata.sh $rll1    ${rll1}_SCRIP.nc


ncremap -5 -m $map  \
        $wdir/testdata/ne120np4pg2_fx1t.nc \
        $wdir/testdata/${rll1}_${mapalg}_mapped.nc

~/codes/nclscript/contour/contour.py \
    -i $wdir/testdata/${rll1}_${mapalg}_mapped.nc \
    -c -40000,40000,1000 -m andes  $var
#      -m europe -c 5 Y16_32
#    -s $wdir/grids/TEMPEST_${rll1}.scrip.nc \


#~/codes/nclscript/contour/contour.py \
#    -i $wdir/testdata/ne120np4_x0topo.nc  \
#    -r 1024x2048 \
#    -c -40000,40000,1000 -m andes  PHIS
