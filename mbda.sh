#!/bin/bash
#
#  scrip to remap using MBDA
#
#  timings:
#  1 node PM-CPU
#
#  ne16np4
#    30s       4.8s
#    15s       12.7s
#    7.5s     1m16s
#
# CA100m
#    30s      11.8s
#    15s     17.9s
#   7.5s    1m21s
#
#  conus 1024x2
#    30s     1m43s
#    15s     2m8s
#   7.5s     3m25s
#
#  conus 1024x3
#    30s     2m57s
#    7.5s    3m59s
#
#  conus 1024x4
#   30s      6m24s
#  7.5s      7m52s
#
wdir=/global/cfs/cdirs/e3sm/taylorm/topo              #wdir=~/proj/topo
grid=/global/cfs/cdirs/e3sm/taylorm/mapping/grids
mbda=/global/cfs/cdirs/e3sm/software/moab/intel/bin/mbda
export OMP_NUM_THREADS=128  # 256 is no faster

# source data
#namesrc=USGS30 ; src=$wdir/usgs-rawdata.nc  
#namesrc=USGS15 ; src=$wdir/usgs-15s-cdf5.nc
namesrc=USGS7.5 src=$wdir/usgs-7.5s.nc

#nameout=ne16np4 ; targ=$wdir/ne16np4_mbda.nc  
#nameout=CA100np4 ; targ=$grid/CA100mnp4_homme_latlon.nc
nameout=conus1024x2  ;targ=$grid/2025-scream-conus-1024x2-ne0np4_mbda.nc
#nameout=conus1024x3 ; targ=$grid/2026-incite-conus-1024x3-ne0np4_mbda.nc
#nameout=conus1024x4 ; targ=$grid/2026-incite-conus-1024x4-ne0np4_mbda.nc





output=$wdir/$namesrc-$nameout-topo.nc

args=("$@")
if [ "$#" -lt "3" ]; then
    echo "MBDA interface script"
fi

cmd="$mbda --fields htopo --source ${src} --target $targ --output $output"
echo $cmd
time $cmd



