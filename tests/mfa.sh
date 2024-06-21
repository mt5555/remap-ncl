#!/bin/bash
#
#  test mfa.py with test case from Pre&Post repo
#  
#

wdir="$HOME/codes/PreAndPostProcessingScripts/regridding/map_file_analysis/test/maps"
#python mfa.py a2o \
#       $wdir/map_ne4pg2_to_oQU480_bilin.200527.nc \
#       $wdir/map_oQU480_to_ne4pg2_mono.200527.nc  \
#       $wdir/domain.lnd.ne4pg2_oQU480.200527.nc


python mfa.py o2a \
       $wdir/map_oQU480_to_ne4pg2_mono.200527.nc  \
       $wdir/map_oQU480_to_ne4pg2_mono.200527.nc  \
       $wdir/domain.lnd.ne4pg2_oQU480.200527.nc





