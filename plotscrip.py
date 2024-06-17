import matplotlib
import matplotlib.pyplot as plt
import netCDF4 as nc
import cartopy
import cartopy.crs as ccrs
import numpy as np
 
# Load the data from the file
data = nc.Dataset('/home/ac.mtaylor/scratch1/mapping/grids/NA1-x_SCRIP.nc')
#data = nc.Dataset('/home/ac.mtaylor/scratch1/mapping/grids/TEMPEST_NE30pg3_scrip.nc')
#data = nc.Dataset('/ascldap/users/mataylo/scratch1/mapping/grids/TEMPEST_ne30pg2.scrip.nc')
 
# Extract the longitude and latitude arrays
#grid_center_lon = data.variables['grid_center_lon'][:]
#grid_center_lat = data.variables['grid_center_lat'][:]
grid_corner_lon = data.variables['grid_corner_lon'][:]
grid_corner_lat = data.variables['grid_corner_lat'][:]
 
def shift_anti_meridian_polygons(lon_poly_coords, lat_poly_coords, eps=40):
    polygons = np.stack((lon_poly_coords, lat_poly_coords), axis=2)
    diff = np.array(np.max(polygons[:,:,0], axis=1) - np.min(polygons[:,:,0], axis=1) > eps)
    lon_coord_mask = polygons[:,:,0] < eps
    lon_coord_mask[~diff,:] = 0
    polygons[lon_coord_mask,0] += 360
    return polygons
def remove_anti_meridian_polygons(lon_poly_coords, lat_poly_coords, eps=40):
    diff = np.array(np.max(lon_poly_coords[:,:], axis=1) - np.min(lon_poly_coords[:,:], axis=1) < eps)
    polygons = np.stack((lon_poly_coords[diff,:], lat_poly_coords[diff,:]), axis=2)
    print("original array: ",lon_poly_coords.shape)
    print("removing anti meridian polygons: ",polygons.shape)
    return polygons


 
# Choose projection
clat=40
clon=-60
proj = ccrs.PlateCarree()
#proj = ccrs.Orthographic(central_latitude=clat, central_longitude=clon) 
#proj = ccrs.Robinson()   
 
# Plot 1: Using lat/lon data directly
ax = plt.axes(projection=proj)
ax.set_global()
#print("get_ext no argument: ",ax.get_extent())
#print("get_ext with proj: ",ax.get_extent(crs=proj))
#print("get_ext with latlon: ",ax.get_extent(crs=ccrs.PlateCarree()))


#lonW = clon-40
#lonE = clon+40
#latS = clat-35
#latN = clat+25
#ax.set_extent([lonW, lonE, latS, latN])

#ax.gridlines()
#ax.coastlines(resolution='110m')
ax.add_feature(cartopy.feature.OCEAN, zorder=0)
#ax.add_feature(cartopy.feature.LAND, zorder=0, edgecolor='black')
ax.add_feature(cartopy.feature.LAND, zorder=0, edgecolor='none')



 
# Plotting cell centers
#ax.scatter(grid_center_lon, grid_center_lat, s=1, transform=ccrs.PlateCarree(), color='blue')
 
# Plotting polygons
# transform to local coordinate system (much faster than letting polycollection transform)
# for lat/lon, transform to [-180,180] in case data is [0,360]:
xpoly  = proj.transform_points(ccrs.PlateCarree(), grid_corner_lon, grid_corner_lat)

#remove bad polygons:
if proj == ccrs.PlateCarree():
    transformed_polygons = shift_anti_meridian_polygons(xpoly[:,:,0], xpoly[:,:,1])
elif proj == ccrs.Robinson():
    transformed_polygons = remove_anti_meridian_polygons(xpoly[:,:,0], xpoly[:,:,1],40*1e5)
else:
    #remove non-visible points:
    xi =  np.all(np.isfinite(xpoly),axis=(1,2))
    xpoly = xpoly[xi,:,:]
    transformed_polygons = np.stack( (xpoly[:,:,0],xpoly[:,:,1]),axis=2)

print("adding polycollection") 
p = matplotlib.collections.PolyCollection(transformed_polygons, facecolor='none', edgecolor='black', alpha=1)
ax.add_collection(p)

#ax.set_title('grid cells')
print("running show")
plt.show()
print("saving png")
plt.savefig("scripcells.png") 

