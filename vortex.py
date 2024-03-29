#!/usr/bin/env python3
# 
# read map file, apply to vortex data, compute error
#
import os, numpy
from netCDF4 import Dataset
from math import pi
from numpy import sin,cos,arctan2,arcsin,cosh,tanh,sqrt
import scipy as sp
import scipy.sparse as sparse


if len(os.sys.argv) < 2:
    print("./vortex.py mapfilename.nc")
    os.sys.exit(1)
mapfile=(os.sys.argv[1])



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
    
    dLonT = arctan2(dY, dX);
    dLonT += numpy.where(dLonT < 0,  2.0 * pi,0)
#    if dLonT < 0.0:
#            dLonT += 2.0 * pi;
    dLatT = arcsin(dZ);
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
    dVt = 3.0 * sqrt(3) / 2.0  / cosh(dRho) / cosh(dRho) * tanh(dRho)

    dOmega = numpy.where( dRho == 0, 0, dVt / dRho)
#    if (dRho == 0.0):
#        dOmega = 0.0
#    else:
#        dOmega = dVt / dRho;
    return (1.0 - tanh(dRho / dD * sin(dLon - dOmega * dT)))


#################################################################################33
#
# main code
#
#################################################################################33
mapf = Dataset(mapfile,"r")

print("reading",mapfile)
S=mapf.variables['S'][:]
row=mapf.variables['row'][:]
col=mapf.variables['col'][:]
row=row-1   # convert to zero indexing
col=col-1

lat_a = mapf.variables['yc_a'][:]
lon_a = mapf.variables['xc_a'][:]
lat_b = mapf.variables['yc_b'][:]
lon_b = mapf.variables['xc_b'][:]
area_b = mapf.variables['area_b'][:]

deg_to_rad=pi/180
print("lat_a",len(lat_a),"min/max",min(lat_a),max(lat_a))
if max(lat_a)>pi:
    print("  converting to radians")
    lat_a = lat_a*deg_to_rad
    lon_a = lon_a*deg_to_rad
print("lat_b",len(lat_b),"min/max",min(lat_b),max(lat_b))
if max(lat_b)>pi:
    print("  converting to radians")
    lat_b = lat_b*deg_to_rad
    lon_b = lon_b*deg_to_rad

n_a = len(lat_a)
n_b = len(lat_b)








data_a=numpy.zeros(n_a)
data_b=numpy.zeros(n_b)
data_b_exact=numpy.zeros(n_b)

# check which is lat, which is lon
# check radians or degrees?  (convert to radians)
print("evaluating vortex function at cell centers...")
data_a=vortex(lon_a,lat_a)
data_b_exact=vortex(lon_b,lat_b)

print("applying mapfile...")
#data_b[row[:]] += data_a[col[:]]*S[:]   # doesnt work
#for i in range(len(S)):                 # very slow
#    data_b[row[i]] += data_a[col[i]]*S[i]
data_b = sparse.coo_matrix((S, (row,col)), shape=(n_b,n_a)) @ data_a
    
# compute error between data_b and data_b_exact
max_err = max( abs(data_b-data_b_exact) ) / max( abs( data_b_exact ))
l2_err = sum( area_b*(data_b-data_b_exact)**2 ) / sum(area_b)
l2_err = sqrt(l2_err)
print("norms of the pointwise error at cell centers:")
print("vortex: relative error l2=%.3e  max=%.3e" % (l2_err,max_err))


mapf.close()
