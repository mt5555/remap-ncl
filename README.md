# remap-ncl

NCL scripts to create and apply SCRIP format mapping file to regrid a
list of NetCDF files.

1. CREATE MAPS
Create a map from SCRIP format grid template files:

% ncl 'src="grid1_scrip.nc"' 'dst="grid2_scrip.nc"' 'base="map_grid1_to_grid2"' make_esmfmap.ncl

which will produce:

map_grid1_to_grid2_aave.nc
map_grid1_to_grid2_bilin.nc
map_grid1_to_grid2_patch.nc


2. CHECK MAP
ESMF sometimes leaves wholes in the map.

ncl 'map="map_grid1_to_grid2.nc"' checkmap.ncl


3. REMAP NETCDF FILES:

Use remap.sh wrapper script:

% ./remap.sh  mapfile.nc  inputfiles*.nc

Or use NCL directly:

$ ncl 'wgtfile="map_grid1_to_grid2_bilin.nc"' 'srcfile="*cam.h0*.nc"' regridfile.ncl

