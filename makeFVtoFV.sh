#!/bin/bash
# 
#
# makeFVtoFV.sh maptype name1 grid1 name2 grid2 
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
    echo "        = bilin_esmf, aave_esmf"
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

map=$wdir/maps/map_${name1}_to_${name2}_$maptype.nc
map_log=$wdir/maps/map_${name1}_to_${name2}_$maptype.log

if [ -f $map ]; then
    echo reusing $map
    exit 0
fi

if [[ $maptype == *"esmf"* ]]; then
    # USE ESMF
    # TR maptypes:  mono,bilin, delaunay, intbilin, intbilingb
    case "$maptype" in
        aave_esmf)
            algarg="--method conserve" ;;
        bilin_esmf)
            algarg="--method bilinear" ;;
        patch_esmf)
            algarg="--method patch" ;;
        *)
            echo "bad maptype  $maptype" ;  exit 1 ;;
    esac

    # we need the "scrip" file.  If we got a *pg2.g file, assume scrip file
    # is *pg2.scrip.nc
    # if we got a np4.g Exodus file, abort
    if [[ $grid1 == *"pg2.g" ]]; then
        base=`basename $grid1 .g`
        grid1=${base}.scrip.nc
    fi
    if [[ $grid2 == *"pg2.g" ]]; then
        base=`basename $grid1 .g`
        grid2=${base}.scrip.nc
    fi
    if [[ $grid1 == *".g" ]]; then
        echo ESMF maps require a SCRIP file. grid1=$grid1
        exit 1
    fi
    if [[ $grid2 == *".g" ]]; then
        echo ESMF maps require a SCRIP file. grid2=$grid2
        exit 1
    fi

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
    exit 0
fi


#
#  use TR 
#
# check TR utilties, existence of grids, make overlap if needed
./make_overlap.sh $name1 $grid1 $name2 $grid2   || exit 1
overlap=$wdir/maps/overlap_${name1}_${name2}.g
if [ ! -f $overlap ]; then
    overlap=$wdir/maps/overlap_${name2}_${name1}.g
fi

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
