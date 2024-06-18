#!/usr/bin/env python3
# 
# read map file, apply to vortex data, compute error
#
import os, numpy, time
from netCDF4 import Dataset
from math import pi
import numpy as np
from numpy import sin,cos,arctan2,arcsin,cosh,tanh,sqrt
import scipy as sp
import scipy.sparse as sparse

# use scipy instead:
# import numba
# @numba.njit()
# def apply_map( data_a, S, row, col,n_b ):
#   data_b=numpy.zeros(n_b)
#   for k in range(len(S)):
#     data_b[row[k]] = data_b[row[k]]  + data_a[col[k]] * S[k]
#   return data_b


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


def test_fields(dlon, dlat, test: str="y16_32"):
    """
    Python subroutine that packages functionality three types of test functions
    
    Args: 
    dlon -- longitude value or vector
    dlat -- latitude value or vector
    test -- corresponds to which test function the user desires.
    Can select one of ("vortex", "y2_2", and "y16_32"), with default = y16_32
    """
    # transform presumed input unit of degrees to radians
    if np.max(dlon) > 3*pi:
        dlon = np.deg2rad(dlon)
        dlat = np.deg2rad(dlat)
        
    if test.lower() == "y16_32":
        return (2 + np.power(np.sin(2 * dlat), 16) * np.cos(16 * dlon))
    elif test.lower() == "y2_2":
        return (2 + np.cos(dlat) * np.cos(dlat) * np.cos(2 * dlon))
    elif test.lower() == "vortex":
        return vortex(dlon,dlat)
    else:
        return("Incorrect test input -- please choose one of 'vortex', 'y2_2', 'y16_32'.")









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

# should we check units?
#if "radian" in infile.variables["xc_a"].units.lower():

deg_to_rad=pi/180
#print("lat_a",len(lat_a),"min/max",min(lat_a),max(lat_a))
if max(lat_a)>2*pi:
    #print("  converting to radians")
    lat_a = lat_a*deg_to_rad
    lon_a = lon_a*deg_to_rad
#print("lat_b",len(lat_b),"min/max",min(lat_b),max(lat_b))
if max(lat_b)>2*pi:
    #print("  converting to radians")
    lat_b = lat_b*deg_to_rad
    lon_b = lon_b*deg_to_rad

n_a = len(lat_a)
n_b = len(lat_b)








data_a=numpy.zeros(n_a)
data_b=numpy.zeros(n_b)
data_b_exact=numpy.zeros(n_b)

#testfield="y16_32"
testfield="vortex"
print("using testfield: ",testfield)
data_a=test_fields(lon_a,lat_a,testfield)
data_b_exact=test_fields(lon_b,lat_b,testfield)



    
print("applying mapfile...")

# NOT VALID:
#data_b[row[:]] += data_a[col[:]]*S[:] 

# SLOW!    ne30np4_to_ne1024pg2:  296s
# tic=time.perf_counter()
# for i in range(len(S)):                 # very slow
#     data_b[row[i]] += data_a[col[i]]*S[i]
# toc=time.perf_counter()
# print(f"python loop:: {toc - tic:0.4f} seconds")

# fastest.  ne30np4_to_ne1024pg2:  0.42s
#tic=time.perf_counter()
data_b = sparse.coo_matrix((S, (row,col)), shape=(n_b,n_a)) @ data_a  # need scypi
#toc=time.perf_counter()
#print(f"apply map via sparse.coo_matrix: {toc - tic:0.4f} seconds")


# # Fast, but not as fast as scypy:   0.61s
# S=numpy.ma.getdata(S)
# data_a=numpy.ma.getdata(data_a)
# row=numpy.ma.getdata(row)
# col=numpy.ma.getdata(col)
# tic=time.perf_counter()
# data_b=apply_map(data_a,S,row,col,n_b)
# toc=time.perf_counter()
# print(f"apply map via numba: {toc - tic:0.4f} seconds")

    
# compute error between data_b and data_b_exact
max_err = max( abs(data_b-data_b_exact) ) / max( abs( data_b_exact ))
l2_err = sum( area_b*(data_b-data_b_exact)**2 ) / sum(area_b)
l2_err = sqrt(l2_err)
print("norms of the pointwise error at cell centers:")
print("vortex: relative error l2=%.3e  max=%.3e" % (l2_err,max_err))


mapf.close()
