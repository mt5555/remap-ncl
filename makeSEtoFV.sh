#!/bin/bash
# 
#
# makeSEtoFV.sh maptype name1 grid1 name2 grid2
#
# TR maptypes:  intbilin, highorder, mono, bilin_tr, intbilin2
#
#
exepath=~/codes/tempestremap
wdir=~/scratch1/mapping

args=("$@")
if [ "$#" -lt "5" ]; then
    echo makeSEtoFV maptype name1 grad1 name2 grid2 
    echo ""
    echo "maptype = intbilin, highorder, mono, ..."
    echo "grid1 = exodus file (default np4)"
    echo "grid2 = FV exodus file"
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

map=$wdir/maps/map_${name1}_to_${name2}_$maptype.nc
map_log=$wdir/maps/map_${name1}_to_${name2}_$maptype.log


case "$maptype" in
    intbilin)
        algarg="--method mono3 --correct_areas --noconserve" ;;
    highorder)
        algarg="--correct_areas" ;;
    mono)
        algarg="--method mono --correct_areas" ;;
    *)
        echo "bad maptype  $maptype" ;  exit 1 ;;
esac

if [ -f $map ]; then
    echo found $map
    echo resusing this file and skippng GenerateOfflineMap
else
    echo "GenerateOfflineMap: $maptype"
    echo "log file: $map_log"
    rm -f $map_log
    $exepath/GenerateOfflineMap --in_mesh $grid1  --out_mesh $grid2  --ov_mesh $overlap \
                                --in_type cgll --in_np 4  --out_type fv  \
                                --out_double --out_format Netcdf4 \
                                $algarg  --out_map $map >& $map_log
fi
