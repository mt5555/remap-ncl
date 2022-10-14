#!/bin/bash
# 
#
# make_overlap.sh name1 grid1 name2 grid2 
#
# make overlap mesh
# if a grid has holes, it should be grid1, otherwise:
#
# ..ERROR: No overlapping face found
# ..This may be caused by mesh B being a subset of mesh A
# ..Try swapping order of mesh A and B, or override with --allow_no_overlap
# ..EXCEPTION (src/OverlapMesh.cpp, Line 1746) Exiting
#
#
exepath=~/codes/tempestremap
wdir=~/scratch1/mapping

args=("$@")
if [ "$#" -lt "4" ]; then
    echo "make_overlap.sh grid1 grid2"
    echo "non-global grids should be grid1"
    exit 1
fi
name1=$1
grid1=$2
name2=$3
grid2=$4



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

overlap_log=''
overlap=$wdir/maps/overlap_${name1}_${name2}.g
overlap2=$wdir/maps/overlap_${name2}_${name1}.g
if [ -f $overlap ]; then
    echo reusing: $overlap
elif [ -f $overlap2 ]; then
    echo reusing: $overlap2
else
    # compute overlap grid, using this log file:
    overlap_log=$wdir/maps/overlap_${name1}_${name2}.log
fi

if [ ! -z $overlap_log ]; then    
    echo "OVERLAP mesh. log file in: $overlap_log"
    rm -f $overlap_log
    if ! $exepath/GenerateOverlapMesh --a $grid1 --b $grid2  --out $overlap   >& $overlap_log ; then
        echo "GenerateOverlapMesh failed"
        exit 1
    fi
    # GenerateOverlapMesh may return 0 even if failed
    if [ ! -f $overlap ]; then
        echo "GenerateOverlapMesh failed"
        exit 1
    fi

fi

