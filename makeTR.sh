#!/bin/bash
# 
#
# makeSEtoSE.sh maptype name1 grid1 name2 grid2
#
# TR maptypes:  highorder, mono
#
#
exepath=~/codes/tempestremap
wdir=~/scratch1/mapping

args=("$@")
if [ "$#" -lt "5" ]; then
    echo makeTR maptype name1 grad1 name2 grid2 
    echo ""
    echo "make TR version of maptype."
    exit 1
fi
maptype=$1
name1=$2
grid1=$3
name2=$4
grid2=$5


if [ ! -f $grid1 ]; then
    if [ -f $wdir/grids/$grid1 ] ; then
        grid1=$wdir/grids/$grid1
    else
        echo ERROR missing: $grid1
        exit 1
    fi
fi
if [ ! -f $grid2 ]; then
    if [ -f $wdir/grids/$grid2 ] ; then
        grid2=$wdir/grids/$grid2
    else
        echo ERROR missing: $grid2
        exit 1
    fi
fi


map=$wdir/maps/map_${name1}_to_${name2}_$maptype.nc
map_log=$wdir/maps/map_${name1}_to_${name2}_$maptype.log
mapt=$wdir/maps/map_${name2}_to_${name1}_${maptype}tr.nc
mapt_log=$wdir/maps/map_${name2}_to_${name1}_${maptype}tr.log

if [ ! -f $map ]; then
    echo missing source map: 
    echo $map
    exit 1
fi

if [ -f $mapt ]; then
    echo found $mapt
    echo resusing this file and skippng GenerateTransposeMap
else
    echo "GenerateTransposeMap: $maptype"
    echo "log file: $mapt_log"
    $exepath/GenerateTransposeMap --in $map --out $mapt >& $mapt_log
    if [ ! -f $mapt ]; then
        echo GenerateTransposeMap failed
        exit 1
    fi

fi
