#! /usr/bin/env python

"""
Script to mask SRTM elevation values above a predefined error threshold
"""

import sys
import os
from pygeotools.lib import iolib
import numpy as np

#Max allowable error values in meters
max_err = 5

hgt_fn = sys.argv[1]
err_fn = sys.argv[2]

print(hgt_fn)

hgt_ds = iolib.fn_getds(hgt_fn)
hgt = iolib.ds_getma(hgt_ds)
err = iolib.fn_getma(err_fn)

#Note: Units of err are mm, multiply by 1000
err[(err > float(max_err*1000))] = np.ma.masked
hgt_masked = np.ma.array(hgt, mask=np.ma.getmaskarray(err))

out_fn = os.path.splitext(hgt_fn)[0]+'_lt%sm_err.tif' % max_err
iolib.writeGTiff(hgt_masked, out_fn, hgt_ds)
