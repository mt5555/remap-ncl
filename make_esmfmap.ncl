load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"


begin
usage = False
if (isvar("src")) then    
  srcFileName = systemfunc("ls "+src)
else
  usage = True
end if

if (isvar("dst")) then    
  dstFileName = systemfunc("ls "+dst)
else
  usage = True
end if

if (isvar("base")) then    
  wgitFileName = base
else
  usage = True
end if
if ( usage ) then
  print("missing arguments.")
  quote = str_get_dq()
  print("usage: ncl 'src="+quote+"filename1.nc"+quote+"' "+\
                   "'dst="+quote+"filename2.nc"+quote+"' "+\
                   "'base="+quote+"map_a_to_b"+quote+"' make_esmfmap.ncl")
  exit
end if
  print("src: "+srcGridName)
  print("dst: "+dstGridName)
  print("map: "+wgtFileName_full)


  ; generate weights
  Opt                      = True
  Opt@ForceOverwrite       = True

  Opt@InterpMethod         = "bilinear"     ; default
  wgtFileName_full = wgtFileName +"_bilin.nc"  
  print("map: "+wgtFileName_full)
  ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileName_full,Opt)

  Opt@InterpMethod         = "conserve"     ; default
  wgtFileName_full = wgtFileName +"_aave.nc"  
  print("map: "+wgtFileName_full)
  ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileName_full,Opt)

  Opt@InterpMethod         = "patch"     ; default
  wgtFileName_full = wgtFileName +"_patch.nc"  
  print("map: "+wgtFileName_full)
  ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileName_full,Opt)


end
