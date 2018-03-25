# nasadem
Scripts to download and process the NASADEM SRTM products

# NASADEM SRTM products (provisional)

See here for more info about NASADEM effort: https://earthdata.nasa.gov/community/community-data-system-programs/measures-projects/nasadem

Provisional tiles downloaded from: https://e4ftl01.cr.usgs.gov/provisional/MEaSUREs/NASADEM/

# Requirements

Some scripts rely on utilities in these packages:

- [`pygeotools`](https://github.com/dshean/pygeotools)
- [`gdal_tools`](https://github.com/dshean/pygeotools)
- [GDAL/OGR](http://www.gdal.org/)
- [NASA Ames Stereo Pipeline (ASP)](https://ti.arc.nasa.gov/tech/asr/intelligent-robotics/ngt/stereo/)
- [NumPy](http://www.numpy.org/)

# Tools

- `srtm_proc.sh` - wrapper to process all downloaded tiles and create mosaics
- `srtm_tilelist.py` - script to fetch tiles for given lat/lon bounds and product type
- `srtm_hdr.sh` - create an ENVI header for the raw tiles
- `srtm_post.sh` - post-process mosaics with error filter, vertical datum shift, reprojection, shaded relief map generation 
- `srtm_errmask.py` - apply max error threshold filter to hgt tiles 

Note: these were written for one-time processing of regional mosaics for existing projects.  They call several other scripts (listed in Requirements section), with limited error checks.  I've tried to clean up and generalize, but don't currently have time for further refinement or usage improvement.  Please treat them as a reference, and feel free to fork and modify hardcoded values for your own needs. 

# High-mountain Asia mosaics

Mosaic parameters:
- Resolution: 30 m
- Extent: (25N, 65E, 47N, 106E)
- Projection: WGS84 (EPSG:4326) and Custom HMA Albers Equal Area

## Available Products:

The following are available for HMA and CONUS.  

All products have external overviews (*.ovr) derived using average resampling.  These enable fast visualization of the otherwise unweildy full-res tif files.

### Elevation

#### Geographic coordinates
- hma_nasadem_hgt.tif - srtmOnly elevation, height above WGS84 Ellipsoid, 32-bit float
- hma_nasadem_hgt_lt5m_err.tif - srtmOnly elevation, masked to preserve pixels with <5 m error, 32-bit float

#### Equal-area projection:
- hma_nasadem_hgt_aea.tif - same as above, reprojected with Albers Equal Area
- hma_nasadem_hgt_lt5m_err_aea.tif - same as above, masked for error <5 m
- hma_nasadem_hgt_aea_hs_az315.tif - shaded relief map, illumination azimuth 315°, elevation 45°
- hma_nasadem_hgt_lt5m_err_aea_hs_az315.tif - shaded relief map

![nasadem_hma_sm](https://user-images.githubusercontent.com/1103530/33039139-dcd13178-cdeb-11e7-9624-6faccd7af3ac.jpg)

### Error
- hma_nasadem_err.tif - elevation error in mm, 16-bit Int

![nasadem_hma_err_sm](https://user-images.githubusercontent.com/1103530/33039134-dca8ec90-cdeb-11e7-9e22-8485e869fb9a.jpg)
Color ramp from 0 to 10 m

### Image
- hma_nasadem_img.tif - mosaiced radar backscatter images, 8-bit

![nasadem_hma_img_sm](https://user-images.githubusercontent.com/1103530/33039136-dcbce3b2-cdeb-11e7-9191-af22b690db98.jpg)
Note that some tiles were missing when this figure was generated. These will be available in the final product release.
