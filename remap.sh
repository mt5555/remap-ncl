#!/bin/tcsh -f
#
#  wrapper for regridfile.ncl
#
if ($#argv < 2 ) then
   echo "remap.sh  mapfile  inputfiles"
   exit
endif

set mapfile = $1
shift
set srcfiles = "$*"

echo "mapfile: "  $mapfile
echo "srcfiles: " $srcfiles

set arg0 = wgtfile=\"$mapfile\"
set arg1 = srcfile=\"$srcfiles\"

ncl  "$arg0" "$arg1"   ~/codes/remap-ncl/regridfile.ncl


