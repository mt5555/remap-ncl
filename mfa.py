#!/usr/bin/env python3
# 
# read map file, apply to vortex data, compute error
#
import os, time, importlib
from netCDF4 import Dataset
import numpy as np
import scipy.sparse as sparse
from plotpoly_hv import plotpoly


if len(os.sys.argv) < 3:
    print("./mfa.py map_type map_file_name.nc    [o2a_flux_map.nc] [domain.lnd.nc]")
    print("map_type=a2o, o2a, a2l, l2a, g2g")
    print("ocean->atm flux map (needed for a2o, o2a and l2a maps)")
    print("domain land file (land fraction, needed for l2a maps")
    os.sys.exit(1)

map_type=os.sys.argv[1]
mapfile=os.sys.argv[2]

print("reading map: ",mapfile)
mapf = Dataset(mapfile,"r")
S=mapf.variables['S'][:]
row=mapf.variables['row'][:]
col=mapf.variables['col'][:]
row=row-1   # convert to zero indexing
col=col-1
n_a = len(mapf['xc_a'])  # removed [:]
n_b = len(mapf['xc_b'])
map_w = sparse.coo_matrix((S, (row,col)), shape=(n_b,n_a))

# grid polygons
lat_a = mapf.variables['yv_a'][:,:]
lon_a = mapf.variables['xv_a'][:,:]
area_a = mapf.variables['area_a'][:]

lat_b = mapf.variables['yv_b'][:,:]
lon_b = mapf.variables['xv_b'][:,:]
area_b = mapf.variables['area_b'][:]

mapf.close()


have_o2a=False
if len(os.sys.argv) >= 4:
    o2a_flux=os.sys.argv[3]
    print("reading o2a flux map: ",o2a_flux)
    fluxf = Dataset(o2a_flux,"r")
    S=fluxf.variables['S'][:]
    row=fluxf.variables['row'][:]
    col=fluxf.variables['col'][:]
    row=row-1   # convert to zero indexing
    col=col-1
    o2a_n_a = len(fluxf['xc_a'])  # removed [:]
    o2a_n_b = len(fluxf['xc_b'])
    o2a_map_w = sparse.coo_matrix((S, (row,col)), shape=(o2a_n_b,o2a_n_a))
    fluxf.close()
    have_o2a=True
    # compute oface_a  (ocean frac on atmosphere grid)
    # assumes MPAS grid which only contains ocean cells:
    ofrac_a = o2a_map_w @ np.ones(o2a_n_a)
    # lfrac_a = 1-ofrac_a
    

have_lfrin=False
if len(os.sys.argv) >= 5:
    domain_lnd=os.sys.argv[4]
    print("reading land domain file: ",domain_lnd)
    lfrin = Dataset(domain_lnd,"r").variables['mask'][:].flatten()
    have_lfrin=True

if map_type=='a2o':
    if not have_o2a:
        print("Error: a2o map analysis requires o2a_flux map.")
        os.sys.exit(1)
elif map_type=='o2a':
    if not have_o2a:
        print("Error: o2a map analysis requires o2a_flux map.")
        os.sys.exit(1)
#elif map_type=='a2l':
#elif map_type=='g2g':
elif map_type=='l2a':
    if not have_o2a:
        print("Error: l2a map analysis requires o2a_flux map.")
        os.sys.exit(1)
    if not have_lfrin:
        print("Error: l2a map analysis requires land domain file.")
        os.sys.exit(1)


#######################################################################
# row and col sums
#######################################################################

mn=np.min(map_w)
mx=np.max(map_w)
print(f"weights min={mn:.13f}  max={mx:.13f}")

tol=1e-8
rowsums = sparse.coo_matrix.sum(map_w,axis=1)
if map_typ=='o2a':
    partial=np.logical_and(ofrac_a>=0,ofrac_a<=(1-tol))
    mn_o=np.min(rowsums[ofrac_a>(1-tol)])
    mn_o=np.max(rowsums[ofrac_a>(1-tol)])
    mn_c=np.min(rowsums[partial])
    mn_c=np.max(rowsums[partial])
    print(f"rowsums (ocean)    min={mn_o:.13f}  max={mn_o:.13f}")
    print(f"rowsums (partial)  min={mn_c:.13f}  max={mn_c:.13f}")
    print(f"ocean / partial ocean computed with tol={tol:.13f}")
else:
    mn=np.min(rowsums)
    mx=np.max(rowsums)
    print(f"rowsums  min={mn:.13f}  max={mn:.13f}")

colsums = map_w.T @ area_b  # should equal area_a
colsums = colsums / area_a
if map_type=='a2o':
    partial=np.logical_and(ofrac_a>=tol,ofrac_a<=(1-tol))
    mn_o=np.min(colsums[ofrac_a>(1-tol)])
    mx_o=np.max(colsums[ofrac_a>(1-tol)])
    mn_c=np.min(colsums[partial])
    mx_c=np.max(colsums[partial])
    print(f"area weighted colsums (ocean)    min={mn_o:.13f}  max={mn_o:.13f}")
    print(f"area weighted colsums (partial)  min={mn_c:.13f}  max={mn_c:.13f}")
    print(f"ocean / partial ocean computed with tol={tol:.13f}")
else:
    mn=np.min(colsums)
    mx=np.max(colsums)
    print(f"area weighted colsums  min={mn:.13f}  max={mx:.13f}")


#######################################################################
# fraction consistency error when mapping to atmosphere grid
# also compute zero-set consistency with fractions:
# error = largest frac_atm_flux (fraction defined by flux map) where
# map_w produces no data
#######################################################################
if map_type[2]=='a':
    if map_type[0]=='l':
        frac_atm = map_w @ lfrin
        frac_atm_flux=1-ofrac_a
    else:
        frac_atm = map_w @ np.ones(o2a_n_a)
        frac_atm_flux=ofrac_a
    zeroset_err = np.max( frac_atm_flux[ (frac_atm==0) ])
    zeroset_count = len( frac_atm_flux[ (frac_atm==0) ] > .001)
    print("zeroset-fractions: atm grid land/ocn fractions at points where map produces no data.  Should be zero")
    print(f"zeroset-fraction max={zeroset_err:.13f}")
    print(f"number of points with zeroset-fraction>.001): {zeroset_count:i}")

    
#######################################################################
# plot grids
#######################################################################
if importlib.util.find_spec("holoviews") is  None:
    print("cant load holoviews module, skipping plots.")
    os.sys.exit(0)

# plot source grid
if map_type[0]='l' and have_lfrin:
    plotgridarea("grid_a_area",lat_a,lon_a,area_a,lfrin)
else:
    plotgridarea("grid_a_area",lat_a,lon_a,area_a)
# plot target grid
if map_type[2]='l' and have_lfrin:
    plotgridarea("grid_b_area",lat_b,lon_b,area_b,lfrin)
else:
    plotgridarea("grid_b_area",lat_b,lon_b,area_b)

plot src test function
plot mapped test function
plot mapped test function error


        
os.sys.exit(0)

data_a=np.zeros(n_a)
data_b=np.zeros(n_b)
data_b_exact=np.zeros(n_b)

data_a=test_fields(lon_a,lat_a,testfield)
data_b_exact=test_fields(lon_b,lat_b,testfield)



    
print("applying mapfile...")

data2 = np.stack( (data_a, np.ones_like(data_a)), axis=1)  # combine into (m,2) matrix
data_b2 = sparse.coo_matrix((S, (row,col)), shape=(n_b,n_a)) @ data2  # need scypi
data_b=data_b2[:,0]
mask_b=(data_b2[:,1] != 0)



data_b=data_b[mask_b] / data_b2[mask_b,1]
data_b_exact=data_b_exact[mask_b]
area_b=area_b[mask_b]


# compute error between data_b and data_b_exact
# only compute error where map(1) <> 0
max_err = max( abs(data_b-data_b_exact) ) / max( abs( data_b_exact ))
l2_err = sum( area_b*(data_b-data_b_exact)**2 ) / sum(area_b)
l2_err = sqrt(l2_err)
print(testfield,": pointwise relative error l2=%.3e  max=%.3e" % (l2_err,max_err))

