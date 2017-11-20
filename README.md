# nasadem
Scripts to download and process the NASADEM SRTM products

David Shean
11/17/17

# NASADEM SRTM products (provisional)

See here for more info about NASADEM effort: https://earthdata.nasa.gov/community/community-data-system-programs/measures-projects/nasadem

Provisional tiles downloaded from: https://e4ftl01.cr.usgs.gov/provisional/MEaSUREs/NASADEM/

# High-mountain Asia composites

Resolution: 30 m
Extent: (25N, 65E, 47N, 106E)
Projection: WGS84 (EPSG:4326) and Custom HMA Albers Equal Area

## Available Products:

The following are available 

All products have external overviews (*.ovr) derived using average resampling.  These enable fast visualization of the otherwise unweildy full-res tif files.

### Elevation
- hma_nasadem_hgt.tif - srtmOnly elevation, height above WGS84 Ellipsoid, 32-bit float
- hma_nasadem_hgt_lt5m_err.tif - srtmOnly elevation, masked to preserve pixels with <5 m error, 32-bit float

Equal-area projection:
- hma_nasadem_hgt_aea.tif
- hma_nasadem_hgt_aea_hs_az315.tif
- hma_nasadem_hgt_lt5m_err_aea.tif
- hma_nasadem_hgt_lt5m_err_aea_hs_az315.tif

### Error
- hma_nasadem_err.tif - elevation error in mm, 16-bit Int

### Image
- hma_nasadem_img.tif - mosaiced radar backscatter images, 8-bit


# Tools

- `srtm_tilelist.py` - script to fetch tiles for given lat/lon bounds and product type
- `srtm_proc.sh` - wrapper to process all downloaded tiles and create mosaics
- `srtm_hdr.sh` - create an ENVI header for the raw tiles
- `srtm_errmask.py` - create masked versions of hgt tiles for given error threshold
