#!/bin/bash
# 
#
# makeSEtoFV_esmf.sh maptype name1 grid1 name2 grid2  
#
# TR maptypes:  aave,bilin,patch
#
#
exepath=~/codes/tempestremap
wdir=~/scratch1/mapping

args=("$@")
if [ "$#" -lt "5" ]; then
    echo makeSEtoFV_esmf.sh maptype name1 grad1 name2 grid2
    echo ""
    echo maptype = aave,bilin,patch
    echo "grid1 = scrip file"
    echo "grid2 = scirp file"
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
./make_overlap.sh $grid1 $grid2 $name1 $name2  || exit 1
overlap=$wdir/maps/overlap_${name1}_${name2}.g
if [ ! -f $overlap ]; then
    overlap=$wdir/maps/overlap_${name2}_${name1}.g
fi


map=$wdir/maps/map_${name1}_to_${name2}_${maptype}_esmf.nc
map_log=$wdir/maps/map_${name1}_to_${name2}_$maptype.log

# TR maptypes:  mono,bilin, delaunay, intbilin, intbilingb
case "$maptype" in
    aave)
        algarg="--method conserve" ;;
    bilin)
        algarg="--method bilinear" ;;
    patch)
        algarg="--method patch" ;;
    *)
        echo "bad maptype  $maptype" ;  exit 1 ;;
esac

if [ -f $map ]; then
    echo found $map
    echo resusing this file and skippng RegridWeightGen
else
    echo "ESMF_RegridWeightGen: $maptype"
    ESMF_RegridWeightGen -d $grid2 -s $grid1  \
                         --dst_regional $algarg --64bit_offset -w $map;
    if [ $? -ne 0 ]; then
        # try with extrapolation turned on:
        echo RegridWeightGen failed. Trying with extrapolation:
        ESMF_RegridWeightGen -d $grid2 -s $grid1   \
                   --extrap_method   nearestidavg \
                   --dst_regional $algarg --64bit_offset -w $map
        if [ $? -ne 0 ]; then
            echo RegridWeightGen failed.
            exit 1
        fi
    fi
fi
