#!/bin/bash
#
#  test mfa.py with test case from Pre&Post repo
#  
#

# ultra lowres  test from Pre&Post:
#wdir="$HOME/codes/PreAndPostProcessingScripts/regridding/map_file_analysis/test/maps"
#python mfa.py o2a \
#       $wdir/map_oQU480_to_ne4pg2_mono.200527.nc  \
#       $wdir/map_oQU480_to_ne4pg2_mono.200527.nc  \
#       $wdir/domain.lnd.ne4pg2_oQU480.200527.nc


#ne256 trigrid with speckling:m
wdir="/sems-data-store/ACME/inputdata"
python mfa.py l2a \
       $wdir/cpl/gridmaps/ne256pg2/map_r0125_to_ne256pg2_bilin.200212.nc \
       $wdir/cpl/gridmaps/ne256pg2/map_oRRS18to6v3_to_ne256pg2_nco.200212.nc \
       $wdir/share/domains/domain.lnd.r0125_oRRS18to6v3.200212.nc






