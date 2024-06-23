#!/bin/bash
#
#  makeVortex.sh shortname grid
#  Create .nc files with vortex, Y2_2 and Y16_32 analytic functions
#
#
exepath=~/codes/tempestremap/
wdir=~/scratch1/mapping
mkdir $wdir/grids
mkdir $wdir/maps

# V2
ocnname=oEC60to30v3
ocnfile=ocean.oEC60to30v3.scrip.181106.nc
atmname=ne30pg2
atmfile=TEMPEST_ne30pg2.scrip.nc

# V3
#ocnfile=ocean.IcoswISC30E3r5.nomask.scrip.20231120.nc
#ocnname=IcoswISC30E3r5
#atmname=ne120pg2
#atmfile=TEMPEST_ne120pg2.scrip.nc


            
# maps needed:
./makeFVtoFV.sh bilin ${ocnname} ${ocnfile} $atmname  ${atmfile}   || exit 1  
./makeFVtoFV.sh bilin $atmname  ${atmfile}  ${ocnname} ${ocnfile}  || exit 1  
# FAILS 2023/7, works 2024/6:
./makeFVtoFV.sh intbilingb ${ocnname} ${ocnfile} $atmname  ${atmfile}
./makeFVtoFV.sh intbilingb $atmname  ${atmfile}  ${ocnname} ${ocnfile}   || exit 1
# FAILS 2023/7, works 2024/6:
./makeFVtoFV.sh intbilin ${ocnname} ${ocnfile} $atmname  ${atmfile}     
./makeFVtoFV.sh intbilin $atmname  ${atmfile}  ${ocnname} ${ocnfile}  || exit 1  
./makeFVtoFV.sh mono ${ocnname} ${ocnfile}  $atmname  ${atmfile}   || exit 1   
./makeFVtoFV.sh mono  $atmname  ${atmfile}  ${ocnname} ${ocnfile}  || exit 1  
./makeFVtoFV.sh fv2  ${ocnname} ${ocnfile}  $atmname  ${atmfile}    || exit 1  
./makeFVtoFV.sh fv2  $atmname  ${atmfile}   ${ocnname} ${ocnfile}  || exit 1  
./makeFVtoFV.sh bilin_esmf  ${ocnname} ${ocnfile}  $atmname  ${atmfile} || exit 1
./makeFVtoFV.sh bilin_esmf  $atmname  ${atmfile}  ${ocnname} ${ocnfile}  || exit 1

               
echo 
name1=${atmname}
grid1=${atmfile}

name2=${ocnname}
grid2=${ocnfile}

# atm->ocn
#python ./vortex.py $wdir/maps/map_${name1}_to_${name2}_fv2.nc          y16_32
#python ./vortex.py $wdir/maps/map_${name1}_to_${name2}_mono.nc          y16_32
#python ./vortex.py $wdir/maps/map_${name1}_to_${name2}_bilin.nc           y16_32
#python ./vortex.py $wdir/maps/map_${name1}_to_${name2}_bilin_esmf.nc       y16_32
#python ./vortex.py $wdir/maps/map_${name1}_to_${name2}_intbilin.nc      y16_32
#python ./vortex.py $wdir/maps/map_${name1}_to_${name2}_intbilingb.nc    y16_32

# ocn->atm
#python ./vortex.py $wdir/maps/map_${name2}_to_${name1}_fv2.nc          y16_32
#python ./vortex.py $wdir/maps/map_${name2}_to_${name1}_mono.nc          y16_32
#python ./vortex.py $wdir/maps/map_${name2}_to_${name1}_bilin.nc         y16_32
#python ./vortex.py $wdir/maps/map_${name2}_to_${name1}_bilin_esmf.nc    y16_32
#python ./vortex.py $wdir/maps/map_${name2}_to_${name1}_intbilin.nc      y16_32
#python ./vortex.py $wdir/maps/map_${name2}_to_${name1}_intbilingb.nc    y16_32

python ./mfa.py o2a $wdir/maps/map_${name2}_to_${name1}_mono.nc   $wdir/maps/map_${name2}_to_${name1}_mono.nc
python ./mfa.py o2a $wdir/maps/map_${name2}_to_${name1}_fv2.nc   $wdir/maps/map_${name2}_to_${name1}_mono.nc
python ./mfa.py o2a $wdir/maps/map_${name2}_to_${name1}_bilin_esmf.nc   $wdir/maps/map_${name2}_to_${name1}_mono.nc
python ./mfa.py o2a $wdir/maps/map_${name2}_to_${name1}_bilin.nc   $wdir/maps/map_${name2}_to_${name1}_mono.nc
python ./mfa.py o2a $wdir/maps/map_${name2}_to_${name1}_intbilin.nc   $wdir/maps/map_${name2}_to_${name1}_mono.nc

# ESMF: errors are much better, but it does not map data two partial cells

