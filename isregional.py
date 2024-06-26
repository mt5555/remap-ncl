#!/usr/bin/env python3
# 
# read scrip file, compute area
#
# return code = 0 "success" meaning grid is regional
# return code = 1 grid is global
#
import os,sys
from netCDF4 import Dataset
from math import pi

if len(os.sys.argv) < 2:
    print("./isregional scripfilename.nc")
    os.sys.exit(1)
scripfile=(os.sys.argv[1])

mapf = Dataset(scripfile,"r")
area=mapf.variables['grid_area'][:]
totarea = sum(area)
regional=0
if abs(totarea/(4*pi)-1) > .001:
    regional=1

#print(scripfile,": regional=",regional," area, area/(4*pi) = ",totarea,totarea/(4*pi))
rcode=1-regional
sys.exit(rcode)

