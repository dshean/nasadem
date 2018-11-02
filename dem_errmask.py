#! /usr/bin/env python

"""
Script to mask DEM values above a predefined error threshold
Currently designed for SRTM and TanDEM-X tile inputs
"""

import sys
import os
from pygeotools.lib import iolib
import numpy as np

if len(sys.argv) != 4:
    sys.exit("Usage: 'dem_errmask.py DEM ERR max_err_m'")
else:
    dem_fn = sys.argv[1]
    err_fn = sys.argv[2]
    max_err = float(sys.argv[3])

#Max allowable error values in meters
#max_err = 1.5
#Multiplier, in case error units are different than DEM units
err_mult = 1.0

#SRTM settings
if os.path.splitext(dem_fn)[1] == 'hgt':
    #max_err = 5.0
    #Note: Units of err are mm, multiply by 1000
    err_mult = 1000.0

print(dem_fn)

dem_ds = iolib.fn_getds(dem_fn)
dem = iolib.ds_getma(dem_ds)
err = iolib.fn_getma(err_fn)

err[err > (max_err*err_mult)] = np.ma.masked
dem_masked = np.ma.array(dem, mask=np.ma.getmaskarray(err))
print(dem.count())
print(dem_masked.count())

out_fn = os.path.splitext(dem_fn)[0]+'_lt%0.1fm_err.tif' % max_err
iolib.writeGTiff(dem_masked, out_fn, dem_ds)
