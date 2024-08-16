#!/bin/bash
# 
#
# makeFVtoSE.sh maptype name1 grid1 name2 grid2 
#
# TR maptypes:  monotr (recommended), mono,  intbilin(new 2022, not tested)
#
# these maps were needed by V1 when running on np4 grids.
# not used anymore and this script is not finished
#
#
exepath=~/codes/tempestremap
wdir=~/scratch1/mapping

args=("$@")
if [ "$#" -lt "5" ]; then
    echo "To configure: "
    echo makeSEtoFV maptype name1 grad1 name2 grid2
    echo ""
    echo "maptype = monotr, ... "
    echo "grid1 = exodus file (default np4)"
    echo "grid2 = FV scrip file"
    echo "name1 = short name of grid1 (e.g. ne30np4)"
    echo "name2 = short name of grid2"
    exit 1
fi
maptype=$1
name1=$2
grid1=$3
name2=$4
grid2=$5


# check TR utilties, existence of grids, make overlap if needed
make_overlap.sh $name1 $grid1 $name2 $grid2  || exit 1
overlap=$wdir/maps/overlap_${name1}_${name2}.g
if [ ! -f $overlap ]; then
    overlap=$wdir/maps/overlap_${name2}_${name1}.g
fi


case "$maptype" in
    monotr)
        algarg="--mono --correct_areas" ;;
    *)
        echo "bad maptype  $maptype" ;  exit 1 ;;
esac

map=$wdir/maps/map_${name1}_to_${name2}_$maptype.nc
map_log=$wdir/maps/map_${name1}_to_${name2}_$maptype.log

if [ -f $map ]; then
    echo found $map
    echo resusing this file and skippng GenerateOfflineMap
else
    # first SE->FV mono:
    ./makeSEtoFV mono $name2 $grid2 $name1 $grid1
    mapmono=$wdir/maps/map_${name2}_to_${name1}_mono.nc


    echo "GenerateTransposeMap: $maptype"
    echo "log file: $mapt_log"
    $exepath/GenerateTransposeMap --in $mapmono --out $map >& $map_log
    if [ ! -f $map ]; then
        echo GenerateTransposeMap failed
        exit 1
    fi

fi

