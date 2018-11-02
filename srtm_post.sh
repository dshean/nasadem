#! /bin/bash

#Post-processing of NASADEM datasets
#Assumes all tiles are downloaded, extracted and a vrt has been built with srtm_proc.sh

#Filters elevation values by error, preserves consistent vertical datum (WGS84 ellipsoid)
#Generates regional equal-area tif mosaic with overviews

topdir=/nobackup/deshean/data/nasadem
srcdir=~/src/nasadem

if [ "$#" -ne 2 ]; then
    echo "Usage is $0 site 'proj4_str'"
    exit 1
fi

site=$1
proj="$2"

#site='hma'
#proj='+proj=aea +lat_1=25 +lat_2=47 +lat_0=36 +lon_0=85 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs '
#site='conus'
#proj='+proj=aea +lat_1=36 +lat_2=49 +lat_0=43 +lon_0=-115 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs '

gdal_opt="-co COMPRESS=LZW -co TILED=YES -co BIGTIFF=IF_SAFER"

cd $topdir/$site

#Remove EGM96 offset from void-filled hgt files
productdir=hgt_merge
ext=hgt
if [ ! -e $productdir/$ext/${site}_nasadem_${productdir}_${ext}_adj.vrt ] ; then 
    echo "Remove EGM96 geoid offset from hgt_merge hgt products"
    parallel --delay 0.1 --progress 'dem_geoid --threads 1 --reverse-adjustment -o {.} {}' ::: $productdir/$ext/*.${ext}
    cd $productdir/$ext
    #Remove log files
    rm *dem_geoid*.txt
    gdalbuildvrt ${site}_nasadem_${productdir}_${ext}_adj.vrt *-adj.tif
    cd $topdir/$site
fi

#Mask elevation values where err >= 5 m
productdir=hgt_srtmOnly_R4
ext=srtmOnly.hgt
max_err=5
if [ ! -e $productdir/$ext/${site}_nasadem_${productdir}_${ext}_lt${max_err}m_err.vrt ] ; then 
    echo "Filtering hgt_srtmOnly_R4 srtmOnly.hgt products, masking pixels with err >= $max_err m"
    parallel --plus --verbose --progress --delay 0.1 "$srcdir/dem_errmask.py {} err_I2/err/{/..}.err $max_err" ::: $productdir/$ext/*.${ext}
    cd $productdir/$ext
    gdalbuildvrt ${site}_nasadem_${productdir}_${ext}_lt${max_err}m_err.vrt *_lt${max_err}m_err.tif
    cd $topdir/$site
fi

#Code to reproject each tile, then mosaic
#Likely faster than reprojecting the large EPSG:4326 mosaic
#parallel -j 16 "gdalwarp $gdal_opt -overwrite -r cubic -t_srs \"$proj\" -dstnodata -32768 -tr 30 30 {} {.}_proj.tif" ::: $fn_list
#fn_list=$(echo $fn_list | sed 's/.hgt/_proj.tif/g')
#gdalbuildvrt nasadem_hgt_srtmOnly_R4_proj.vrt $fn_list 

#Reproject all mosaics to our regional equal-area projection and build overviews
cd $topdir/$site
echo "Reprojecting mosaics and building overviews"
vrt_list=$(ls */*/*vrt)
#Note: may need to hardcode dstnodata value, specifically for err mosaic
#parallel --verbose --progress "ndv=$(gdalinfo {} | grep NoData | awk -F= '{print $NF}'); gdalwarp $gdal_opt -overwrite -r cubic -dstnodata $ndv -t_srs \"$proj\" -tr 30 30 {} {.}_proj.tif; gdaladdo_ro.sh {.}_proj.tif" ::: $vrt_list
parallel --verbose "if [ ! -e {.}_proj.tif ] ; then gdalwarp $gdal_opt -overwrite -r cubic -t_srs \"$proj\" -tr 30 30 {} {.}_proj.tif; fi ; if [ ! -e {.}_proj.tif.ovr ] ; then gdaladdo_ro.sh {.}_proj.tif; fi" ::: $vrt_list

#Generate shaded relief maps and build overviews
echo "Generating shaded relief maps and building overviews"
hs_list="hgt_merge/hgt/${site}_nasadem_hgt_merge_hgt_adj_proj.tif \
    hgt_srtmOnly_R4/srtmOnly.hgt/${site}_nasadem_hgt_srtmOnly_R4_srtmOnly.hgt_proj.tif \
    hgt_srtmOnly_R4/srtmOnly.hgt/${site}_nasadem_hgt_srtmOnly_R4_srtmOnly.hgt_lt${max_err}m_err_proj.tif"
parallel --verbose --progress "if [ ! -e {.}_hs_az315.tif ] ; then hs.sh {}; fi ; if [ ! -e {.}_hs_az315.tif.ovr ] ; then gdaladdo_ro.sh {.}_hs_az315.tif; fi" ::: $hs_list
