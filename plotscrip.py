import matplotlib
import matplotlib.pyplot as plt
import cartopy
import cartopy.crs as ccrs
import netCDF4 as nc
import numpy as np
import sys

if (len(sys.argv)>=2):
    name=sys.argv[1]
else:
    name='TEMPEST_ne30pg2.scrip.nc'
    print("no SCRIP file given. looking for TEMPEST_ne30pg2.scrip.nc")
if (len(sys.argv)>=3):
    region=sys.argv[2]
else:
    region='global'
    print("no region given, using 'global'")



# Load the data from the file
data = nc.Dataset(name)

 
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


 
# Choose projection and region
if region=='global':
    proj = ccrs.PlateCarree()
    ax = plt.axes(projection=proj)
    ax.set_global()

if region=='global-robinson':
    proj = ccrs.Robinson()
    ax = plt.axes(projection=proj)
    ax.set_global()

if region=='NA1':
    proj = ccrs.PlateCarree()
    ax = plt.axes(projection=proj)
    lonW = -110
    lonE = 10
    latS = 0
    latN = 70
    ax.set_extent([lonW, lonE, latS, latN])

if region=='ortho':
    clat=40
    clon=-60
    proj = ccrs.Orthographic(central_latitude=clat, central_longitude=clon) 


gl=ax.gridlines(linewidth=0.2,alpha=0.5)
gl.left_labels = True
gl.bottom_labels = True

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
if "proj=eqc" in proj.srs:
    transformed_polygons = shift_anti_meridian_polygons(xpoly[:,:,0], xpoly[:,:,1])
elif "proj=robin" in proj.srs:
    transformed_polygons = remove_anti_meridian_polygons(xpoly[:,:,0], xpoly[:,:,1],40*1e5)
else:
    #remove non-visible points:
    xi =  np.all(np.isfinite(xpoly),axis=(1,2))
    xpoly = xpoly[xi,:,:]
    transformed_polygons = np.stack( (xpoly[:,:,0],xpoly[:,:,1]),axis=2)

print("adding polycollection") 
p = matplotlib.collections.PolyCollection(transformed_polygons, facecolor='none',
      edgecolor='black', linewidth=.1,antialiased=True)
ax.add_collection(p)

#ax.set_title('grid cells')
#print("running show")
#plt.show()
outname=name.split(".nc")[0]
outname=outname+".png"
print("saving png:",outname)
plt.savefig(outname,dpi=1200) 


#grid_corner_lon = data.variables['grid_corner_lon'][:]
#grid_corner_lat = data.variables['grid_corner_lat'][:]
area  = data.variables['area'][:]
outname=name.split(".nc")[0]
outname=outname+"-resolution.png"
plotpoly(grid_corner_lon,grid_corner_lat,Rearth_km*np.sqrt(area),outname,title="resolution (km)")


