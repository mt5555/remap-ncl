#!/usr/bin/env python3
# 
# read map file, apply to vortex data, compute error
#
from math import pi
import numpy as np
from numpy import sin,cos,arctan2,arcsin,cosh,tanh,sqrt

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
    
    dLonT = arctan2(dY, dX);
    dLonT += np.where(dLonT < 0,  2.0 * pi,0)
#    if dLonT < 0.0:
#            dLonT += 2.0 * pi;
    dLatT = arcsin(dZ);
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
    dVt = 3.0 * sqrt(3) / 2.0  / cosh(dRho) / cosh(dRho) * tanh(dRho)

    dOmega = np.where( dRho == 0, 0, dVt / dRho)
#    if (dRho == 0.0):
#        dOmega = 0.0
#    else:
#        dOmega = dVt / dRho;
    return (1.0 - tanh(dRho / dD * sin(dLon - dOmega * dT)))


def test_fields(dlon, dlat, test: str="y16_32"):
    """
    Python subroutine that packages functionality three types of test functions
    
    Args: 
    dlon -- longitude value or vector
    dlat -- latitude value or vector
    test -- corresponds to which test function the user desires.
    Can select one of ("vortex", "y2_2", and "y16_32"), with default = y16_32
    """
    # transform presumed input unit of degrees to radians
    if np.max(dlon) > 3*pi:
        dlon = np.deg2rad(dlon)
        dlat = np.deg2rad(dlat)
        
    if test.lower() == "y16_32":
        return (2 + np.power(np.sin(2 * dlat), 16) * np.cos(16 * dlon))
    elif test.lower() == "y2_2":
        return (2 + np.cos(dlat) * np.cos(dlat) * np.cos(2 * dlon))
    elif test.lower() == "vortex":
        return vortex(dlon,dlat)
    else:
        return("Incorrect test input -- please choose one of 'vortex', 'y2_2', 'y16_32'.")







