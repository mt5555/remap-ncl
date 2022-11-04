#!/usr/bin/env python3
# 
# read two files, compute l2 and max error 
#
from __future__ import print_function
import os, numpy
from netCDF4 import Dataset
from math import pi
from numpy import sin,cos,arctan2,arcsin,cosh,tanh,sqrt

if len(os.sys.argv) < 4:
    print("./referror fieldname ref.nc new.nc")
    os.sys.exit(1)
field=os.sys.argv[1]
file1=os.sys.argv[2]
file2=os.sys.argv[3]


f1 = Dataset(file1,"r")
f2 = Dataset(file2,"r")

data1=f1.variables[field][:]
data2=f2.variables[field][:]
area=f2.variables['area'][:]

# compute error between data1 and data2
max_err = max( abs(data1-data2) ) / max( abs( data2 ))
l2_err = sum( area*(data1-data2)**2 ) / sum(area)
l2_err = sqrt(l2_err)
print(field,": relative error l2=%.3e  max=%.3e" % (l2_err,max_err))

