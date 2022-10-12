remap utilities

a collection of scripts using NCO, ncremap and TempestRemap to
create grids and mapping files

SCRIP files:

makeSE.sh     make Exodus and SCRIP files for SE grids
makeRLL.sh    use ncremap to make SCRIP files for lat/lon grids

mapping files:

makeSEtoFV.sh
makeFVtoFV.sh   todo
makeFVtoSE.sh   (not finished)
esmf options?


vortex.sh     give a mapping file, compute L2 and max error for the vortex analytic function


plotting: figure out how to plot vortex output


--method bilin      (bilinear, FV->FV)  (same as ESMF)
--method delaunay   (Delaunay triangulation, FV->FV)
--method intbilin"  (integrated bilinear *->FV)
--method intbilingb (generalized Barycentric coords, FV->FV)
--method mono3      ( SE->FV (good), FV->SE (bad)

