# remap-ncl

NCL scripts to create and apply SCRIP format mapping file to regrid a
list of NetCDF files.

1. CREATE MAPS
Create a map from SCRIP format grid template files:

./makemap.sh grid1_scrip.nc grid2_scrip.nc map_grid1_to_grid2

which will produce:

map_grid1_to_grid2_aave.nc
map_grid1_to_grid2_bilin.nc
map_grid1_to_grid2_patch.nc


2. CHECK MAP
ESMF sometimes leaves wholes in the map.

./checkmap.sh map_grid1_to_grid2.nc


3. REMAP NETCDF FILES:

% ./remap.sh  mapfile.nc  inputfiles*.nc

Or use NCL directly:

$ ncl 'wgtfile="map_grid1_to_grid2_bilin.nc"' 'srcfile="*cam.h0*.nc"' regridfile.ncl

