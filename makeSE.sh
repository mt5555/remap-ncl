#!/bin/bash
#
#  make SE template files
#
#
exepath=~/codes/tempestremap/
wdir=~/scratch1/mapping/grids


args=("$@")
if [ "$#" -lt "1" ]; then
    echo "makeSE.sh NE [PG]"
    exit 1
fi
PG=2
if [ "$#" -ge "2" ]; then
    PG=$2
fi


cd $wdir
NE=$1
atmname=ne${NE}
atmgrid=TEMPEST_${atmname}.g
atm_pg=TEMPEST_${atmname}pg${PG}.g
atm_scrip=TEMPEST_${atmname}pg${PG}.scrip.nc

if [ -f $atm_scrip ] ; then
    echo reusing $atm_scrip
    exit 0
fi


# generate a Tempest NE8 mesh.  should match HOMME
$exepath/GenerateCSMesh --alt --res $NE  --file $atmgrid
if [ "$PG" -ge 2 ]; then
    $exepath/GenerateVolumetricMesh --in $atmgrid --out $atm_pg --np $PG --uniform
    $exepath/ConvertMeshToSCRIP --in $atm_pg --out $atm_scrip
else
    # PG1 case is just the .g grid
    $exepath/ConvertMeshToSCRIP --in $atmgrid --out $atm_scrip    
fi






