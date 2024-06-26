
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

def shift_anti_meridian_polygons(lon_poly_coords, lat_poly_coords, eps=40):
    """Shift polygons that are split on the anti-meridian for visualization
    
    Parameters
    ----------
    lon_poly_coords : ndarray(n, v)
        longitudinal coordinates of each vertex of each polygon
    lat_poly_coords : ndarray(n, v)
        latitudinal coordinates of each vertex of each polygon
    eps : float (default 10)
        Tolerance for polygons to shift
    
    Returns
    -------
    polygons : ndarray(n, v, 2)
        Combined longitude and latitude coordinates for all polygons (including shifted ones)
    """
    polygons = np.stack((lon_poly_coords, lat_poly_coords), axis=2)
    diff = np.array(np.max(polygons[:,:,0], axis=1) - np.min(polygons[:,:,0], axis=1) > eps)
    lon_coord_mask = polygons[:,:,0] < eps   # all polygons on left edge
    lon_coord_mask[~diff,:] = 0              # mask=0 for subset of left polygons which are not cut
    #polygons_new=polygons[diff,:,:]            # set of all split polygons
    polygons[lon_coord_mask,0] = polygons[lon_coord_mask,0] + 360

    #lon_coord_mask = polygons_new[:,:,0] > eps  # coords on right side
    #polygons_new[lon_coord_mask,0] = polygons_new[lon_coord_mask,0] - 360
    # also return polygons_new, and "diff", so we can extract
    # data_new = data[diff] 
    return polygons


def plotpoly(xlat,xlon,data,outname=None, title='',
              proj=ccrs.PlateCarree(),
              xlim=(-180.,180), ylim=(-90.,90.),
              clim=None,colormap=None,mask=1
):

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

    # center plot at lon=0,lat=0:
    proj=ccrs.PlateCarree()
    xpoly  = proj.transform_points(proj, xlon, xlat)
    
    #print("matplotlib/polycollection... ",end='')
    dpi=1200
    start= time.time()
    
    # adjust cells into polycollection format:
    xpoly = shift_anti_meridian_polygons(xpoly[:,:,0],xpoly[:,:,1])
    corners=np.stack([xpoly[:,:,0],xpoly[:,:,1]],axis=2)
    
    ax = pyplot.axes(projection=ccrs.PlateCarree())
    ax.set_global()
    
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




