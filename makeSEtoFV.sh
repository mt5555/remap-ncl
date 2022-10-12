#!/bin/bash
# 
#
# makeSEtoFV.sh maptype grid1 grid2 name1 name2 
#
# TR maptypes:  intbilin, highorder, mono, bilin_tr, intbilin2
#
#
set exepath = ~/codes/tempestremap
set wdir = ~/scratch1/mapping

args=("$@")
if [ "$#" -lt "5" ]; then
    echo "To configure: "
    echo "makeSEtoFV maptype grad1 grid2 name1 name2"
    echo ""
    echo "maptype = intbilin, highorder, mono, ..."
    echo "grid1 = exodus file (default np4)"
    echo "grid2 = FV scrip file"
    echo "name1 = short name of grid1 (e.g. ne30np4)"
    echo "name2 = short name of grid2"
    exit 1
fi

if [ ! -x  $exepath/GenerateOverlapMesh ]; then
    echo TR utilties missing
    exit 1
fi
if [ ! -f $grid1 ]; then
    echo ERROR missing: $grid1
    exit 1
fi
if [ ! -f $grid2 ]; then
    echo ERROR missing: $grid2
    exit 1
fi

map=$wdir/map_${name1}_to_${name2}_$maptype.nc
map_log=$wdir/map_${name1}_to_${name2}_$maptype.log

overlap=$wdir/overlap_${name1}_${name2}.g
overlap_log=$wdir/overlap_${name1}_${name2}.g

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

echo "GenerateOfflineMap: $maptype"
echo "log file: $map_log"
rm -f $map_log
$exepath/GenerateOfflineMap --in_mesh $grid1  --out_mesh $grid2  --ov_mesh $overlap \
  --in_type cgll --in_np 4  --out_type fv  \
  --out_double --out_format Netcdf4 \
  $algarg  --out_map $map >& $map_log

