#! /usr/bin/env python

"""
Script to mask SRTM elevation values above a predefined error threshold
"""

#cd /nobackupp8/deshean/rpcdem/hma/nasadem
#parallel --delay 0.1 'srtm_errmask.py {} err/{/.}.err' ::: srtmOnly/*hgt
#cd srtmOnly; gdalbuildvrt -o hma_nasadem_hgt_lt5m_err.vrt n*lt5m_err.tif

import sys
import os
from pygeotools.lib import iolib
import numpy as np

#Max allowable error values in meters
max_err = 5.0
#Note: Units of err are mm
max_err *= 1000

hgt_fn = sys.argv[1]
err_fn = sys.argv[2]

print(hgt_fn)

hgt_ds = iolib.fn_getds(hgt_fn)
hgt = iolib.ds_getma(hgt_ds)
err = iolib.fn_getma(err_fn)

err[(err > max_err)] = np.ma.masked
hgt_masked = np.ma.array(hgt, mask=np.ma.getmaskarray(err))

out_fn = os.path.splitext(hgt_fn)[0]+'_lt5m_err.tif'
iolib.writeGTiff(hgt_masked, out_fn, hgt_ds)
