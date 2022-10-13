#!/bin/bash
# 
#
# makeSEtoFV.sh maptype name1 grid1 name2 grid2 
#
# TR maptypes:  mono,bilin, delaunay, intbilin, intbilingb
#
#
exepath=~/codes/tempestremap
wdir=~/scratch1/mapping

args=("$@")
if [ "$#" -lt "5" ]; then
    echo makeSEtoFV.sh maptype name1 grad1 name2 grid2
    echo ""
    echo "maptype = mono,bilin, delaunay, intbilin, intbilingb"
    echo "grid1 = FV exodus or scrip file"
    echo "grid2 = FV exodus or scirp file"
    echo "name1 = short name of grid1 (e.g. ne30np4)"
    echo "name2 = short name of grid2"
    exit 1
fi
maptype=$1
name1=$2
grid1=$3
name2=$4
grid2=$5



if [ ! -x  $exepath/GenerateOfflineMap ]; then
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




# check TR utilties, existence of grids, make overlap if needed
./make_overlap.sh $name1 $grid1 $name2 $grid2   || exit 1
overlap=$wdir/maps/overlap_${name1}_${name2}.g
if [ ! -f $overlap ]; then
    overlap=$wdir/maps/overlap_${name2}_${name1}.g
fi


map=$wdir/maps/map_${name1}_to_${name2}_$maptype.nc
map_log=$wdir/maps/map_${name1}_to_${name2}_$maptype.log

# TR maptypes:  mono,bilin, delaunay, intbilin, intbilingb
case "$maptype" in
    mono)
        algarg="--correct_areas" ;;
    bilin)
        algarg="--method bilin --noconserve" ;;
    intbilin)
        algarg="--method intbilin --noconserve" ;;
    intbilingb)
        algarg="--method intbilingb --noconserve" ;;
    delaunay)
        echo "todo: put in delaunay arguments" ;  exit 1 ;;
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
                                --in_type fv --in_np 1  --out_type fv --out_np 1 \
                                --out_double --out_format Netcdf4 \
                                $algarg  --out_map $map >& $map_log
    if [ ! -f $map ]; then
        echo GenerateOfflineMap failed
        exit 1
    fi
fi
