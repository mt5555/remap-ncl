#!/bin/bash
#
#  makeVortex.sh shortname grid
#  Create .nc files with vortex, Y2_2 and Y16_32 analytic functions
#
#
exepath=~/codes/tempestremap/
wdir=~/scratch1/mapping
cd $wdir/testdata

args=("$@")
if [ "$#" -lt "2" ]; then
    echo "makeVortex.sh name grid"
    exit 1
fi
if [ ! -x  $exepath/GenerateTestData ]; then
    echo TR utilties missing
    exit 1
fi

name=$1
grid1=$2

if [ ! -f $grid1 ]; then
    if [ -f $wdir/grids/$grid1 ] ; then
        grid1=$wdir/grids/$grid1
    else
        echo ERROR missing: $grid1
        exit 1
    fi
fi

output=$wdir/testdata/${name}_testdata.nc
if [ -f $output ] ; then
    echo testdata found: $output
    exit 1
fi
if [[ $name == *"np4"* ]]; then
    np=4
    echo "Generating analytc test data on SE np4 grid"
    $exepath/GenerateTestData --mesh $grid1 --test 1 --gll --np $np --out testdata_1.nc
    $exepath/GenerateTestData --mesh $grid1 --test 2 --gll --np $np --out testdata_2.nc
    $exepath/GenerateTestData --mesh $grid1  --test 3 --gll --np $np  --out testdata_3.nc
else
    echo "Generating analytic test data on FV grid"
    $exepath/GenerateTestData --mesh $grid1 --test 1  --out testdata_1.nc
    $exepath/GenerateTestData --mesh $grid1 --test 2  --out testdata_2.nc
    $exepath/GenerateTestData --mesh $grid1  --test 3  --out testdata_3.nc
fi



ncrename -v Psi,Y2_2 testdata_1.nc
ncrename -v Psi,Y16_32 testdata_2.nc
ncrename -v Psi,vortex testdata_3.nc
mv -f testdata_1.nc  $output
ncks -A -v Y16_32 testdata_2.nc  $output
ncks -A -v vortex testdata_3.nc  $output
rm -f testdata_?.nc

