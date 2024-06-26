#!/usr/bin/env python3
# 
# read map file, apply to vortex data, compute error
#
import os, time, importlib
from netCDF4 import Dataset
import numpy as np
import scipy.sparse as sparse
#from plotpoly_hv import plotpoly
from plotpoly_mpl import plotpoly
from test_fields import test_fields


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

area_a = mapf.variables['area_a'][:]
area_b = mapf.variables['area_b'][:]


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

print("\nNote: "
"Row sums should be 1, except for partial cells (if any) where they should be in [0,1]. "
"Column sums are area weighted and area normalized.  For conservative maps, they should "
"be 1, except for partial cells (if any) where they shoudl be in [0,1]. "
"The zeroset-fraction metric gives the atm grid land/ocn fraction at points where atmosphere "
"target maps produce no data.  Measures the error reconstructing fields on the atmosphere "
"grid with sources from land and ocean.")

print("")
Rearth_km = 6378.1                # radius of earth, in km
sqrtarea=np.sqrt(area_a)*Rearth_km
tot_area_a=sum(area_a)/(4*np.pi)
if tot_area_a < 1.1:    # some bilin maps have garbage in area
    print(f"src grid dx   min={np.min(sqrtarea):.2f}km max={np.max(sqrtarea):.2f}km"
          f" area/4pi={tot_area_a:.3f} n_a={n_a}")
else:
    print(f"src grid (bad area)  n_a={n_a}")

sqrtarea=np.sqrt(area_b)*Rearth_km
tot_area_b=sum(area_b)/(4*np.pi)
if tot_area_b < 1.1:  # some bilin maps have garbage in area
    print(f"dst grid dx   min={np.min(sqrtarea):.2f}km max={np.max(sqrtarea):.2f}km"
          f" area/4pi={tot_area_b:.3f} n_b={n_b}")
else:
    print(f"dst grid (bad area)   n_b={n_b}")
if (have_o2a):
    print(f"o2a flux map: n_a={o2a_n_a} n_b={o2a_n_b}")
if (have_lfrin):
    print(f"land domain file: n_a={len(lfrin)}")

src_mask=1
dst_mask=1
if have_lfrin and map_type[0]=='l': src_mask=lfrin
if have_lfrin and map_type[2]=='l': dst_mask=lfrin
    
if map_type=='a2o':
    if not have_o2a:
        print("Error: a2o map analysis requires o2a_flux map.")
        os.sys.exit(1)
    if n_a != o2a_n_b:
        print("Error: atmosphere grid does not match o2a_flux map.")
        os.sys.exit(1)
    if n_b != o2a_n_a:
        print("Error: ocean grid does not match o2a_flux map.")
        os.sys.exit(1)
elif map_type=='o2a':
    if not have_o2a:
        print("Error: o2a map analysis requires o2a_flux map.")
        os.sys.exit(1)
    if n_b != o2a_n_b:
        print("Error: atmosphere grid does not match o2a_flux map.")
        os.sys.exit(1)
    if n_a != o2a_n_a:
        print("Error: ocean grid does not match o2a_flux map.")
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
    if n_b != o2a_n_b:
        print("Error: atmosphere grid size does not match o2a_flux map.")
        os.sys.exit(1)
    if n_a != len(lfrin):
        print("Error: land grid does not match domain.lnd grid.")
        os.sys.exit(1)


#######################################################################
# row and col sums
#######################################################################
tol=1e-8
mn=np.min(map_w)
mx=np.max(map_w)
print(f"map weights:     min,max={mn:.13f} {mx:.13f}")


rowsums = sparse.coo_matrix.sum(map_w,axis=1)    
if map_type[2]=='o2a':
    # no need to do this for l2a maps, since they are global and we assume lfrin=[0,1]
    partial=np.logical_and(ofrac_a>=0,ofrac_a<=(1-tol))
    mn_o=np.min(rowsums[ofrac_a>(1-tol)])
    mn_o=np.max(rowsums[ofrac_a>(1-tol)])
    mn_c=np.min(rowsums[partial])
    mn_c=np.max(rowsums[partial])
    print(f"rowsums(ocean)   min/max={mn_o:.13f} {mn_o:.13f} tol={tol:.1e}")
    print(f"rowsums(partial) min/max={mn_c:.13f} {mn_c:.13f} tol={tol:.1e}")
else:
    mn=np.min(rowsums)
    mx=np.max(rowsums)
    print(f"rowsums          min/max={mn:.13f} {mn:.13f}")

if tot_area_a>1.1 or tot_area_b>1.1:
    print("skipping colsums due to bad area data")
else:
    colsums = map_w.T @ area_b  # should equal area_a
    colsums = colsums / area_a
    if map_type=='a2o':
        partial=np.logical_and(ofrac_a>=tol,ofrac_a<=(1-tol))
        mn_o=np.min(colsums[ofrac_a>(1-tol)])
        mx_o=np.max(colsums[ofrac_a>(1-tol)])
        mn_c=np.min(colsums[partial])
        mx_c=np.max(colsums[partial])
        print(f"colsums(ocean)   min,max={mn_o:.13f} {mn_o:.13f} tol={tol:.1e}")
        print(f"colsums(partial) min,max={mn_c:.13f} {mn_c:.13f} tol={tol:.1e}")
    else:
        mn=np.min(colsums)
        mx=np.max(colsums)
        print(f"colsums          min,max={mn:.13f} {mx:.13f}")


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
    zeroset = frac_atm_flux[ (frac_atm==0) ]
    zeroset_err = np.max(zeroset)
    zeroset_count = sum(1 for x in (zeroset>0.001) if x) 
    print(f"zeroset-fraction     max={zeroset_err:.13f} ({zeroset_count} cells have err>.001)")



if tot_area_b>1.1:    
    print("Error processing area_b, skipping mapping Y16_32 error calculation.")
    os.sys.exit(1)

#######################################################################
# mapping error
#######################################################################
# grid centers
lat_a = mapf.variables['yc_a'][:]
lon_a = mapf.variables['xc_a'][:]
lat_b = mapf.variables['yc_b'][:]
lon_b = mapf.variables['xc_b'][:]

data_a=test_fields(lon_a,lat_a,"y16_32")
data_b_exact=test_fields(lon_b,lat_b,"y16_32")
data2 = np.stack( (src_mask*data_a, src_mask*np.ones_like(data_a)), axis=1)  # combine into (m,2) matrix
data_b2 = map_w @ data2
data_b=data_b2[:,0]
mask_b=data_b2[:,1] != 0
data_b[mask_b]=data_b[mask_b] / data_b2[mask_b,1]

data_b2=data_b[mask_b]
data_b_exact2=data_b_exact[mask_b]
area_b2=area_b[mask_b]


# compute mapping error between data_b and data_b_exact
# only at cells where mask_b=True, possibly split into full and partial fraction cells
max_normalization=max(abs(data_b_exact2))
l2_normalization=sum( area_b2*data_b_exact2**2) / sum(area_b2)
                      
if map_type[2]=='a':
    if map_type[0]=='o': frac=ofrac_a
    if map_type[0]=='l': frac=1-ofrac_a
    # compute error over full cells:   
    mask_full=(frac[mask_b]>(1-tol))
    mask_partial=~mask_full

    data_b3=data_b2[mask_full]
    data_b_exact3=data_b_exact2[mask_full]
    area_b3=area_b2[mask_full]
    max_err = max( abs(data_b3-data_b_exact3) )       / max_normalization
    l2_err = sum( area_b3*(data_b3-data_b_exact3)**2 ) / sum(area_b3) / l2_normalization
    l2_err = np.sqrt(l2_err)
    print("Y16_32 pointwise relative error, full cells:     l2=%.3e  max=%.3e" % (l2_err,max_err))
    # set data range for error plot based on interior cells
    mx = max( abs(data_b3-data_b_exact3) ) 
    clim_error=(-mx,mx)


    data_b3=data_b2[mask_partial]
    data_b_exact3=data_b_exact2[mask_partial]
    area_b3=area_b2[mask_partial]
    max_err = max( abs(data_b3-data_b_exact3) )  / max_normalization
    l2_err = sum( area_b3*(data_b3-data_b_exact3)**2 ) / sum(area_b3) / l2_normalization
    l2_err = np.sqrt(l2_err)
    print("Y16_32 pointwise relative error, partial cells:  l2=%.3e  max=%.3e" % (l2_err,max_err))

else:
    max_err = max( abs(data_b2-data_b_exact2) )        / max_normalization
    l2_err = sum( area_b2*(data_b2-data_b_exact2)**2 ) / sum(area_b2) / l2_normalization
    l2_err = np.sqrt(l2_err)
    print("Y16_32 pointwise relative error l2=%.3e  max=%.3e" % (l2_err,max_err))
    mx = max( abs(data_b2-data_b_exact2) ) 
    clim_error=(-mx,mx)



#######################################################################
# plot grids
#######################################################################

# grid polygons
lat_a = mapf.variables['yv_a'][:,:]
lon_a = mapf.variables['xv_a'][:,:]
lat_b = mapf.variables['yv_b'][:,:]
lon_b = mapf.variables['xv_b'][:,:]

# plot source grid
if tot_area_a<1.1:
    plotpoly(lat_a,lon_a,Rearth_km*np.sqrt(area_a),"srcgrid-dx.png",title="resolution (km)",mask=src_mask)
# plot target grid
if tot_area_b<1.1:
    plotpoly(lat_b,lon_b,Rearth_km*np.sqrt(area_b),"dstgrid-dx.png",title="resolution (km)",mask=dst_mask)    

plotpoly(lat_b,lon_b,data_b,"map_field.png",title="mapped Y16_32",mask=mask_b)
error=data_b_exact-data_b
plotpoly(lat_b,lon_b,error,"map_error.png",title="Y16_32 map error",clim=clim_error,
colormap='Spectral',mask=mask_b)

