#!/bin/tcsh -f
#
#  wrapper for regridfile.ncl
#
if ($#argv < 1 ) then
   echo "checkmap.sh mapfile"
   exit
endif

set dirname=`dirname $0`
set mapfile = $1

echo "mapfile: "  $mapfile

set arg0 = map=\"$mapfile\"

ncl  "$arg0" $dirname/checkmap.ncl

