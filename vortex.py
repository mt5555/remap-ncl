#
# Converted from TR C++ code
#
# Find the rotated longitude and latitude of a point on a sphere
# with pole at (dLonC, dLatC)
# input: dLonT,dLatT
# output: dLonT,dLatT   (may not work in python)
#
def RotatedSphereCoord(dLonC,dLatC,dLonT,dLatT):
    dSinC = sin(dLatC);
    dCosC = cos(dLatC);
    dCosT = cos(dLatT);
    dSinT = sin(dLatT);
    
    dTrm  = dCosT * cos(dLonT - dLonC);
    dX = dSinC * dTrm - dCosC * dSinT;
    dY = dCosT * sin(dLonT - dLonC);
    dZ = dSinC * dSinT + dCosC * dTrm;
    
    dLonT = atan2(dY, dX);
    if dLonT < 0.0:
            dLonT += 2.0 * M_PI;
    dLatT = asin(dZ);
    return dLonT,dLatT

#
#  return the value of the vortex function at dLon,dLat
#
def vortex(dLon_in,dLat_in):
    dLon0 = 0.0;
    dLat0 = 0.6;
    dR0 = 3.0;
    dD = 5.0;
    dT = 6.0;

    dLon,dLat = RotatedSphereCoord(dLon0, dLat0, dLon_in, dLat_in)

    dRho = dR0 * cos(dLat)
    dVt = 3.0 * sqrt(3.0) / 2.0  / cosh(dRho) / cosh(dRho) * tanh(dRho)

    dOmega;
    if (dRho == 0.0):
        dOmega = 0.0
    else:
        dOmega = dVt / dRho;
    return (1.0 - tanh(dRho / dD * sin(dLon - dOmega * dT)))




code:
read in mapping file
compute vortex at sourc grid x_c,y_c
map to target grid x_c,y_c
compute vortex on target grid
compute l2 and max error

  do i=0,n_s-1
    ic=col(i)-1        # convert to zero indexing
    ir=row(i)-1
    if (mod(i,1000000).eq.0) then
       print(i+"/"+n_s)
    end if
    colsum(ic)=colsum(ic)+S(i)*area_b(ir)
    colnum(ic)=colnum(ic)+1
    rowsum(ir)=rowsum(ir)+S(i)
    rownum(ir)=rownum(ir)+1
  end do


row_k dot xin = xout(k)
mask?
  only considier xout(k) where mask_b=1?


