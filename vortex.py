#!/usr/bin/env python3
# 
# read map file, apply to vortex data, compute error
#
import os, time
from netCDF4 import Dataset
from math import pi
import numpy as np
from numpy import sin,cos,arctan2,arcsin,cosh,tanh,sqrt
import scipy as sp
import scipy.sparse as sparse

from plotpoly_mpl import plotpoly
from test_fields import test_fields

# use scipy instead:
# import numba
# @numba.njit()
# def apply_map( data_a, S, row, col,n_b ):
#   data_b=numpy.zeros(n_b)
#   for k in range(len(S)):
#     data_b[row[k]] = data_b[row[k]]  + data_a[col[k]] * S[k]
#   return data_b


if len(os.sys.argv) < 2:
    print("./vortex.py mapfilename.nc [vortex,y16_23,y2_2]")
    os.sys.exit(1)
mapfile=(os.sys.argv[1])
plotfile=mapfile.split(".nc")[0]
testfield='vortex'
if len(os.sys.argv) >= 3:
    testfield=os.sys.argv[2]


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
if max(abs(lat_a))>1.1*pi:
    #print("  converting to radians")
    lat_a = lat_a*deg_to_rad
    lon_a = lon_a*deg_to_rad
#print("lat_b",len(lat_b),"min/max",min(lat_b),max(lat_b))
if max(abs(lat_b))>1.1*pi:
    #print("  converting to radians")
    lat_b = lat_b*deg_to_rad
    lon_b = lon_b*deg_to_rad

n_a = len(lat_a)
n_b = len(lat_b)








data_a=np.zeros(n_a)
data_b=np.zeros(n_b)
data_b_exact=np.zeros(n_b)

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
tic=time.perf_counter()
data2 = np.stack( (data_a, np.ones_like(data_a)), axis=1)  # combine into (m,2) matrix
data_b2 = sparse.coo_matrix((S, (row,col)), shape=(n_b,n_a)) @ data2  # need scypi
data_b=data_b2[:,0]
mask_b=(data_b2[:,1] != 0)


toc=time.perf_counter()
print(f"apply map via sparse.coo_matrix: {toc - tic:0.4f} seconds")


# # Fast, but not as fast as scypy:   0.61s
# S=np.ma.getdata(S)
# data_a=np.ma.getdata(data_a)
# row=np.ma.getdata(row)
# col=np.ma.getdata(col)
# tic=time.perf_counter()
# data_b=apply_map(data_a,S,row,col,n_b)
# toc=time.perf_counter()
# print(f"apply map via numba: {toc - tic:0.4f} seconds")


# remove points where map(1) == 0
# devide by map(1) to compute correct error:
data_b=data_b[mask_b] / data_b2[mask_b,1]
data_b_exact=data_b_exact[mask_b]
area_b=area_b[mask_b]


# compute error between data_b and data_b_exact
# only compute error where map(1) <> 0
max_err = max( abs(data_b-data_b_exact) ) / max( abs( data_b_exact ))
l2_err = sum( area_b*(data_b-data_b_exact)**2 ) / sum(area_b)
l2_err = sqrt(l2_err)
print(testfield,": pointwise relative error l2=%.3e  max=%.3e" % (l2_err,max_err))


# read in the cell polygons
lat_b = mapf.variables['yv_b'][:,:]
lon_b = mapf.variables['xv_b'][:,:]
lat_b = lat_b[mask_b,:]
lon_b = lon_b[mask_b,:]


if np.max(np.abs(lat_b))<1.1*pi:
    #print("  converting to degrees")
    lat_b = lat_b/deg_to_rad
    lon_b = lon_b/deg_to_rad

plotpoly(lat_b,lon_b,data_b,plotfile+'_field.png')
#plotpoly(lat_b,lon_b,data_b-data_b_exact,plotfile+'_error.png',colormap='Spectral')

# error plot zoomed in over UK, with bounds specified
plotpoly(lat_b,lon_b,data_b-data_b_exact,plotfile+'_error.png',clim=(-.005,.005),
         colormap='Spectral',xlim=(-35,35),ylim=(10,80))

