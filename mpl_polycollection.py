
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
    lon_coord_mask = polygons[:,:,0] < eps
    lon_coord_mask[~diff,:] = 0

    polygons[lon_coord_mask,0] = polygons[lon_coord_mask,0] + 360
    return polygons


def polyplot(xlat,xlon,area,outname):

    # convert to degrees, if necessary
    if np.max(np.abs(xlat))<1.1*pi:
        xlat=xlat*180/pi
        xlon=xlon*180/pi


    mn=float(min(area))
    mx=float(max(area))
    colormap='Spectral'
    print(f"poly_plot(): plotting {len(area)} cells. data min/max= {mn:.3},{mx:.3}")
    mn=-.005
    mx=.005
    clev=(mn,mx)
    
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
    #p = matplotlib.collections.PolyCollection(corners, array=area, edgecolor='face',alpha=1)
    p = matplotlib.collections.PolyCollection(corners, array=area, edgecolor='none',alpha=1)
    p.set_clim(clev)
    p.set_cmap(colormap)
    ax.add_collection(p)
    fig.colorbar(p)
    
    matplotlib.pyplot.savefig(outname,dpi=dpi,orientation="portrait",bbox_inches='tight')
    end= time.time()
    #print(f"{end-start:.2f}s")
    return 0




