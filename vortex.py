#!/usr/bin/env python
# 
# read map file, apply to vortex data, compute error
#
from __future__ import print_function
import os, numpy
from netCDF4 import Dataset


mapfile="~/scratch1/mapping/maps/map_ne30np4_to_ne1024pg2_intbilin.nc"
mapf = Dataset(mapfile,"r")
#print(mapf.data_model)
#print(mapf.variables.keys())
#for d in mapf.dimensions.items():
#    print(d)
#print(S.dimensions)

S=mapf.variables['S'][:]
row=mapf.variables['row'][:]
col=mapf.variables['col'][:]
lat_a = mapf.variables['xc_a'][:]
lon_a = mapf.variables['yc_a'][:]
lat_b = mapf.variables['xc_b'][:]
lon_b = mapf.variables['yc_b'][:]
area_b = mapf.variables['area_b'][:]

n_a = len(lat_a)
n_b = len(lat_b)

mapf.close()
os.sys.exit(1)






#
# Converted from TR C++ code
#
# Find the rotated longitude and latitude of a point on a sphere
# with pole at (dLonC, dLatC)
# input: dLonT,dLatT
# output: dLonT,dLatT   (may not work in python)
#
def RotatedSphereCoord(dLonC,dLatC,dLonT,dLatT):
    dSinC = sin(dLatC);
    dCosC = cos(dLatC);
    dCosT = cos(dLatT);
    dSinT = sin(dLatT);
    
    dTrm  = dCosT * cos(dLonT - dLonC);
    dX = dSinC * dTrm - dCosC * dSinT;
    dY = dCosT * sin(dLonT - dLonC);
    dZ = dSinC * dSinT + dCosC * dTrm;
    
    dLonT = atan2(dY, dX);
    if dLonT < 0.0:
            dLonT += 2.0 * M_PI;
    dLatT = asin(dZ);
    return dLonT,dLatT

#
#  return the value of the vortex function at dLon,dLat
#
def vortex(dLon_in,dLat_in):
    dLon0 = 0.0;
    dLat0 = 0.6;
    dR0 = 3.0;
    dD = 5.0;
    dT = 6.0;

    dLon,dLat = RotatedSphereCoord(dLon0, dLat0, dLon_in, dLat_in)

    dRho = dR0 * cos(dLat)
    dVt = 3.0 * sqrt(3.0) / 2.0  / cosh(dRho) / cosh(dRho) * tanh(dRho)

    dOmega;
    if (dRho == 0.0):
        dOmega = 0.0
    else:
        dOmega = dVt / dRho;
    return (1.0 - tanh(dRho / dD * sin(dLon - dOmega * dT)))




data_a=numpy.zeros(n_a)
data_b=numpy.zeros(n_b)
data_b_exact=numpy.zeros(n_b)

# check which is lat, which is lon
# check radians or degrees?  (convert to radians)
for i in range(n_a):
    data_a[i]=vortex(xc_a[i],yc_a[i])
for i in range(n_b):
    data_b_exact[i]=vortex(xc_b[i],yc_b[i])


for i in range(len(S)):
    ic=col(i)-1        # convert to zero indexing
    ir=row(i)-1
    data_b[ir] += data_a[ic]*S[i]

# compute error between data_b and data_b_exact
max_err = max( abs(data_b-data_b_exact) ) / max( abs( data_b_exact ))
l2_err = sum( area_b*(data_b-data_b_exact)**2 ) / sum(area_b)
l2_err = sqrt(l2_err)

