#!/bin/bash
#
#  make SE template files
#
#
exepath=~/codes/tempestremap/
wdir=~/scratch1/mapping
cd $wdir

NE=1024
atmname=ne${NE}
atmgrid=TEMPEST_${atmname}.g
atm_pg2=TEMPEST_${atmname}pg2.g
atm_scrip=TEMPEST_${atmname}pg2.scrip.nc
atm_scrip1=TEMPEST_${atmname}pg1.scrip.nc

# generate a Tempest NE8 mesh.  should match HOMME
$exepath/GenerateCSMesh --alt --res $NE  --file $atmgrid
$exepath/GenerateVolumetricMesh --in $atmgrid --out $atm_pg2 --np 2 --uniform
$exepath/ConvertMeshToSCRIP --in $atm_pg2 --out $atm_scrip

# make a "pg1" grid
#$exepath/ConvertMeshToSCRIP --in $atmgrid --out $atm_scrip1



