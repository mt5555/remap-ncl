#!/bin/tcsh -f
#
#  wrapper for regridfile.ncl
#
if ($#argv < 3 ) then
   echo "makemap.sh srcgrid dstgrid map_base_name"
   exit
endif

set  src = $1
set  dst = $2
set base = $3


limit stacksize 512M
set exe = /projects/ccsm/esmf-6.3.0rp1/bin/binO/Linux.intel.64.openmpi.default/ESMF_RegridWeightGen
set esmf = "mpirun -np 8  $exe"


# NCL on skybridge cant find ESMF path
#set argsrc = src=\"$src\"
#set argdst = dst=\"$dst\"
#set argmap = base=\"$base\"
#ncl  "$argsrc" "$argdst" "$argmap"  ~/codes/remap-ncl/make_esmfmap.ncl


# run ESMF directly

set map = {$base}_bilin.nc
$esmf  -d $dst -s $src  -w $map --method bilinear

set map = {$base}_aave.nc
$esmf  -d $dst -s $src  -w $map --method conserve

#set map = {$base}_patch.nc
#$esmf  -d $dst -s $src  -w $map --method patch
