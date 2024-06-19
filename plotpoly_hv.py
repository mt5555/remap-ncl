import numpy as np

import shapely
import pyarrow as pa
import sys
import spatialpandas
import cartopy.crs as ccrs

import holoviews as hv
from holoviews.operation.datashader import rasterize as hds_rasterize
import time

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


def polygons_to_geodataframe(lon_poly_coords, lat_poly_coords, data, eps=10):
    """Takes Coordinates for polygons and converts them to a geodataframe for Holoviews Visualization

    Data Structure Transition & Explanation: 
        numpy -> shapely -> pyarrow -> spatialpandas multipolygonarray -> spatialpandas geodataframe

        pyarrow is a Python implementation of Apache Arrow which optimizes data transition from JSON
        to dataframes that gives us the majority of the speedup seen from using the geodataframe 
        instead of just numpy arrays. This function currently only takes milliseconds to run as well.
    
    Parameters
    ----------
    lon_poly_coords : ndarray(n, v)
        longitudinal coordinates of each vertex of each polygon
    lat_poly_coords : ndarray(n, v)
        latitudinal coordinates of each vertex of each polygon
    data : ndarray(n)
        The data to assign to each of the n polygons
    eps : float (default 10)
        Tolerance for polygons to shift
    
    Returns
    -------
    polygons : spatialpandas.GeoDataFrame columns: {'geometry': polygons, 'faces': data}
        Geodataframe of all cell polygons with data linked to each cell
    """

    polygons = shift_anti_meridian_polygons(lon_poly_coords, lat_poly_coords)
    geo = shapely.polygons(polygons)

    arr_flat, part_indices = shapely.get_parts(geo, return_index=True)
    offsets1 = np.insert(np.bincount(part_indices).cumsum(), 0, 0)
    arr_flat2, ring_indices = shapely.get_rings(arr_flat, return_index=True)
    offsets2 = np.insert(np.bincount(ring_indices).cumsum(), 0, 0)
    coords, indices = shapely.get_coordinates(arr_flat2, return_index=True)
    offsets3 = np.insert(np.bincount(indices).cumsum(), 0, 0)
    coords_flat = coords.ravel()
    offsets3 *= 2

    _parr3 = pa.ListArray.from_arrays(pa.array(offsets3), pa.array(coords_flat))
    _parr2 = pa.ListArray.from_arrays(pa.array(offsets2), _parr3)
    parr = pa.ListArray.from_arrays(pa.array(offsets1), _parr2)

    polygons = spatialpandas.geometry.MultiPolygonArray(parr)
    gdf = spatialpandas.GeoDataFrame({'geometry': polygons})
    gdf = gdf.assign(faces = data)
    return gdf



def plotpoly(lat_poly_coords, lon_poly_coords, data, filepath=None, title='',
              plot_bbox=None, width=4000, height=1800, proj=ccrs.PlateCarree(),
              xlim=(-180.,180), ylim=(-90.,90.),
              clim=None,colormap=None,mask=1
):
    """Holoviews polygon plot of the data associated with each cell - can be output to a file or generated in a notebook
    
    Parameters
    ----------
    lon_poly_coords : ndarray(n, v)
        longitudinal coordinates of each vertex of each polygon
    lat_poly_coords : ndarray(n, v)
        latitudinal coordinates of each vertex of each polygon
    data : ndarray(n)
        The data to assign to each of the n polygons
    filepath : string (default None)
        The filepath of where the file should be saved and its name (e.g. ~/plots/test.png)
    plot_bbox : list(list(int, int), list(int, int)) (default None)
        Latitude and Longitude bounds for zooming capabilities on rendering
    proj : ccrs Projection (default ccrs.PlateCarree())
        Which projection to use with the bounding box
    """

    if lon_poly_coords.shape != lat_poly_coords.shape:
        print(f"Dimension mismatch between longitude: {lon_poly_coords.shape}, and latitude: {lat_poly_coords.shape}")
        return
    elif len(lon_poly_coords) != len(data):
        print(f"Dimension mismatch between number of cells: {len(lon_poly_coords)} and number of data points: {len(data)}")
        return

    # if mask present, remove masked cells
    if not np.isscalar(mask):
        data=data[mask]
        lon_poly_coords = lon_poly_coords[mask,:]
        lat_poly_coords = lat_poly_coords[mask,:]
    

    mn=float(min(data))
    mx=float(max(data))
    if (colormap==None):
        colormap='Plasma'

    print(f"poly_plot(): plotting {len(data)} cells. data min/max= {mn:.3},{mx:.3}")

    # center at lat=lon=0
    xlon  = proj.transform_points(ccrs.PlateCarree(), lon_poly_coords,lat_poly_coords)
    lon_poly_coords=xlon[:,:,0]
    lat_poly_coords=xlon[:,:,1]
    #lat_poly_coords=xlon[:,:,2] # radius

    gdf = polygons_to_geodataframe(np.ma.getdata(lon_poly_coords), np.ma.getdata(lat_poly_coords), np.ma.getdata(data))

    

    cbar_opts={}
    #cbar_opts={'width': round(.02*width)}
    #cbar_opts={'label': "km"}

    hv.extension('matplotlib') # need to load extension before setting options
    hv_polys = hv.Polygons(gdf, vdims=['faces']).opts(color='faces')
    
    rasterized = hds_rasterize(hv_polys,height=height, width=width)
    rasterized.opts(data_aspect=1)
    rasterized.opts(xlabel='', ylabel='', clabel='')
    rasterized.opts(xlim=xlim, ylim=ylim)
    rasterized.opts(fig_inches=width/72)
    rasterized.opts(cmap=colormap,colorbar=True,colorbar_opts=cbar_opts)
    if (clim!=None):
        rasterized.opts(clim=clim)
    rasterized.opts(fontscale=10)
    rasterized.opts(title=title)
        
    fig=hv.render(rasterized)  
    if (filepath!=None):
        fig.savefig(filepath, bbox_inches='tight')





