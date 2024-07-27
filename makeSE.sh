#!/bin/bash
#
#  make SE template files given "NE" or a Exodus .g file
#  
#
#
exepath=~/codes/tempestremap/
if ! [ -x $exepath/GenerateCSMesh ]; then
   # might be in our path, via conda:
   exepath=`which GenerateCSMesh`
   exepath=`dirname $exepath`
   echo $exepath
   echo add some error checking if using this option
   exit 1
fi
wdir=~/scratch1/mapping/grids


args=("$@")
if [ "$#" -lt "1" ]; then
    echo "makeSE.sh NE or file.g [PG]"
    exit 1
fi
PG=2
if [ "$#" -ge "2" ]; then
    PG=$2
fi


cd $wdir
if [[ $1 == *".g"* ]]; then
    atmname=`basename $1 .g`
    echo $atmname
    atmgrid=$1
    atm_pg=${atmname}pg${PG}.g
    atm_scrip=${atmname}pg${PG}.scrip.nc
else
   NE=$1
   atmname=ne${NE}
   atmgrid=TEMPEST_${atmname}.g
   atm_pg=TEMPEST_${atmname}pg${PG}.g
   atm_scrip=TEMPEST_${atmname}pg${PG}.scrip.nc

   # generate a Tempest NE8 mesh.  should match HOMME
   $exepath/GenerateCSMesh --alt --res $NE  --file $atmgrid
fi


if [ -f $atm_scrip ] ; then
    echo reusing $atm_scrip
    exit 0
fi


if [ "$PG" -ge 2 ]; then
    $exepath/GenerateVolumetricMesh --in $atmgrid --out $atm_pg --np $PG --uniform
    $exepath/ConvertMeshToSCRIP --in $atm_pg --out $atm_scrip
else
    # PG1 case is just the .g grid
    $exepath/ConvertMeshToSCRIP --in $atmgrid --out $atm_scrip    
fi






