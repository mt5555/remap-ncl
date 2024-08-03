remap utilities

a collection of scripts using python, NCO, ncremap and TempestRemap to
create grids and mapping files

Assumes  tempestremap installed in ~/codes/tempestremap
./configure --with-netcdf=`nc-config --prefix`  --without-hdf5


SCRIP files:

makeSE.sh     make Exodus and SCRIP files for SE grids
makeRLL.sh    use ncremap to make SCRIP files for lat/lon grids

mapping files:

makeSEtoFV.sh
makeFVtoFV.sh   
makeFVtoSE.sh   (not finished)



vortex.sh     give a mapping file, compute L2 and max error for the vortex analytic function

isregiona.sh     return code = 0 if a grid is regional
make_overlap.sh  TR overlap grid, called by mapping file scripts
polyplot_mpl.sh  plot test functions, map error, using MPL's polycollection
polyplot_hv.sh   plot test functions, map error, using holoviews