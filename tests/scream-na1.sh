#!/bin/bash
#
#  create North Atlantic grid "NA1"
#  plot 10x reduced version
#  make SCREAM ne1024pg2 -> NA1 mapping file
#  make SCREAM ne30pg2 -> NA1 mapping file (for testing)
#
exepath=~/codes/tempestremap/
wdir=~/scratch1/mapping

mapalg=intbilin

./make_regRLL.sh NA1
name2=NA1
#grid2=no exodus file for RLL grids
grid2s=NA1-800x1000_SCRIP.nc

NE=30
./makeSE.sh $NE
name1=ne${NE}pg2
grid1=TEMPEST_ne${NE}pg2.g
grid1s=TEMPEST_ne${NE}pg2.scrip.nc

# make overlap grid: regional grid needs to be first:
./make_overlap.sh $name2 $grid2s $name1 $grid1


./makeFVtoFV.sh $mapalg $name1 $grid1s $name2  $grid2s  || exit 1
map=$wdir/maps/map_${name1}_to_${name2}_${mapalg}.nc
if [ ! -f $map ]; then
    echo missing map: $map
    exit 1
fi

./vortex.py $map


