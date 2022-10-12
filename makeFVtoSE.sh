#!/bin/bash
# 
#
# makeFVtoSE.sh maptype grid1 grid2 name1 name2 
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
    echo "makeSEtoFV maptype grad1 grid2 name1 name2"
    echo ""
    echo "maptype = monotr, ... "
    echo "grid1 = exodus file (default np4)"
    echo "grid2 = FV scrip file"
    echo "name1 = short name of grid1 (e.g. ne30np4)"
    echo "name2 = short name of grid2"
    exit 1
fi
maptype=$1
grid1=$2
grid2=$3
name1=$4
name2=$5

if [ ! -x  $exepath/GenerateOverlapMesh ]; then
    echo TR utilties missing
    exit 1
fi
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

overlap=$wdir/maps/overlap_${name1}_${name2}.g
overlap_log=$wdir/maps/overlap_${name1}_${name2}.g

echo "OVERLAP mesh. log file in: $overlap_log"
if [ -f $overlap ]; then
    echo found $overlap
    echo resusing this file and skippng GenerateOverlapMesh
else
    rm -f $overlap_log
    if ! $exepath/GenerateOverlapMesh --a $grid1 --b $grid2  --out $overlap   >& $overlap_log ; then
        echo "GenerateOverlapMesh failed"
        exit 1
    fi
fi

TODO

