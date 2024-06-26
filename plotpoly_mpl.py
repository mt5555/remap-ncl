
#
# simpile routine to plot a function using matplotlib's polycollection
#
 

import time
import numpy as np
from netCDF4 import Dataset
import cartopy.crs as ccrs
import matplotlib
from matplotlib import pyplot
from matplotlib.collections import PolyCollection
from math import pi

def shift_anti_meridian_polygons(polygons, eps=40):
    #shift polygons that are split on the anti-meridian for visualization

    diff = np.array(np.max(polygons[:,:,0], axis=1) - np.min(polygons[:,:,0], axis=1) > eps)
    lon_coord_mask = polygons[:,:,0] < eps   # all polygons on left edge
    lon_coord_mask[~diff,:] = 0              # mask=0 for subset of left polygons which are not cut
    polygons_new=polygons[diff,:,:]            # set of all split polygons
    polygons[lon_coord_mask,0] = polygons[lon_coord_mask,0] + 360

    lon_coord_mask = polygons_new[:,:,0] > eps  # coords on right side
    polygons_new[lon_coord_mask,0] = polygons_new[lon_coord_mask,0] - 360
    # also return polygons_new, and "diff", so we can extract
    # data_new = data[diff] 
    return [polygons,polygons_new,diff]



def plotpoly(xlat,xlon,data,outname=None, title='',
              proj=ccrs.PlateCarree(),
              xlim=(-180.,180), ylim=(-90.,90.),
              clim=None,colormap=None,mask=1
):

    #print("matplotlib/polycollection... ",end='')
    start= time.time()

    #proj=ccrs.Robinson()
    #clat=40; clon=-60;  proj = ccrs.Orthographic(central_latitude=clat, central_longitude=clon) 
    #print(proj.srs)

    dpi=1200
    
    # if mask present, remove masked cells
    if not np.isscalar(mask):
        data=data[mask]
        xlon = xlon[mask,:]
        xlat = xlat[mask,:]
        #count = sum(1 for x in mask if x)

    # convert to degrees, if necessary
    if np.max(np.abs(xlat))<1.1*pi:
        xlat=xlat*180/pi
        xlon=xlon*180/pi
        
    mn=float(min(data))
    mx=float(max(data))
    print(f"poly_plot(): plotting {len(data)} cells. data min/max= {mn:.3},{mx:.3}")
    if clim == None:
        clim=(mn,mx)
    if colormap==None:
        if mn*mx < 0: colormap='Spectral'
        else: colormap='plasma'
    
    # transform into desired coordinate system:
    xpoly  = proj.transform_points(ccrs.PlateCarree(), xlon, xlat)

    # fix and duplicate cut cells
    if "proj=eqc" in proj.srs:
        # duplicate cut polygons on left and right edge of plot
        [xpoly,xpoly_new,mask_new] = shift_anti_meridian_polygons(xpoly)
        corners=np.concatenate((xpoly[:,:,0:2],xpoly_new[:,:,0:2]),axis=0)
        data=np.concatenate((data,data[mask_new]),axis=0)
    if "proj=robin" in proj.srs:
        # remove all cut polygons
        eps=40*1e5
        mask_keep = np.array(np.max(xpoly[:,:,0], axis=1) - np.min(xpoly[:,:,0], axis=1) < eps)
        corners=xpoly[mask_keep,:,0:2]
        data=data[mask_keep]
    if "proj=ortho" in proj.srs:
        #remove non-visible points:
        mask_keep =  np.all(np.isfinite(xpoly),axis=(1,2))
        corners = xpoly[mask_keep,:,0:2]
        data=data[mask_keep]
    
    fig=matplotlib.pyplot.figure()
    ax = matplotlib.pyplot.axes(projection=proj)
    ax.set_global()
    p = matplotlib.collections.PolyCollection(corners, array=data, edgecolor='none',antialiased=False)
    p.set_clim(clim)
    p.set_cmap(colormap)
    ax.add_collection(p)
    fig.colorbar(p)
    
    ax.set_title(title)
    if outname != None:
        matplotlib.pyplot.savefig(outname,dpi=dpi,orientation="portrait",bbox_inches='tight')
    end= time.time()
    #print(f"{end-start:.2f}s")
    return 0
