#!/usr/bin/env python3
# 
# read map file, apply to vortex data, compute error
#
from __future__ import print_function
import os, numpy
from netCDF4 import Dataset
from math import pi
from numpy import sin,cos,arctan2,arcsin,cosh,tanh,sqrt

if len(os.sys.argv) < 3:
    print("./referror exact.nc mappedfile.nc")
    os.sys.exit(1)
file1=(os.sys.argv[1])
file2=(os.sys.argv[2])

f1 = Dataset(file1,"r")
f2 = Dataset(file2,"r")

print("reading data files...")
data1=f1.variables['vortex'][:]
data2=f2.variables['vortex'][:]
area=f2.variables['area'][:]

# compute error between data1 and data2
max_err = max( abs(data1-data2) ) / max( abs( data2 ))
l2_err = sum( area*(data1-data2)**2 ) / sum(area)
l2_err = sqrt(l2_err)
print("vortex: l2,max relative error: ",l2_err,max_err)

