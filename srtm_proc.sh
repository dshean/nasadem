#! /bin/bash

#Define projection
#CONUS
#epsg=32611
#proj='+proj=aea +lat_1=36 +lat_2=49 +lat_0=43 +lon_0=-115 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs '
#site='conus'
#HMA
#epsg=32644
proj='+proj=aea +lat_1=25 +lat_2=47 +lat_0=36 +lon_0=85 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs '
site='hma'

gdal_opt="-co COMPRESS=LZW -co TILED=YES -co BIGTIFF=IF_SAFER"

ext='hgt'
#ext='img'
#ext='err'

#Modify lat/lon bounds and generate with the get_srtm_tilelist.py script
urllist=${site}_nasadem_tilelist_${ext}.txt
echo -n > $urllist
srtm_tilelist.py >> $urllist 

url_zip_list=$(cat $urllist | awk -F'/' '{print $NF}')
fn_list=$(ls *${ext}.zip)

echo -n > ${urllist%.*}_missing.txt
for i in $url_zip_list
do
    if ! echo $fn_list | grep -q $i ; then
        grep $i $urllist >> ${urllist%.*}_missing.txt
    fi
done

#For USGS or s3 sources 
#For provisional NASADEM products, need NASA Earthdata account
uname=dshean
#Need to hardcode password when using GNU parallel 
pw=''

cat ${urllist%.*}_missing.txt | parallel --delay 1 -j 16 --progress "wget --user $uname --password $pw -nc -q {}"

#Serial wget from file
#wget --user $uname --ask-password -nc -i $urllist

fn_list=''
for i in *zip
do
    if [ ! -e ${i%.*} ] ; then 
        fn_list+=" $i"
    fi
done

parallel 'unzip {}' ::: $fn_list

fn_list=$(ls *.${ext})
#Generate hdr and prj sidecar files
parallel 'srtm_hdr.sh {}' ::: $fn_list

#Build mosaic in original WGS84 coordinates
gdalbuildvrt ${site}_nasadem_${ext}.vrt $fn_list
gdaladdo_ro.sh ${site}_nasadem_${ext}.vrt
gdal_translate $gdal_opt ${site}_nasadem_${ext}.vrt ${site}_nasadem_${ext}.tif
gdalwarp -overwrite $gdal_opt -r cubic -t_srs "$proj" -tr 30 30 nasadem_${ext}.vrt nasadem_${ext}_30m.tif

#Should mask elevation values where err >= 32769

exit

gdalwarp -overwrite $gdal_opt -r cubic -t_srs "$proj" -tr 90 90 nasadem_${ext}.vrt nasadem_${ext}_90m.tif
hs.sh nasadem_${ext}_90m.tif
gdaladdo_ro.sh nasadem_${ext}_90m.tif
gdaladdo_ro.sh nasadem_${ext}_90m_hs_az315.tif

#fn_list=$(ls *raw)

#NASADEM hgt_srtmOnly_R4 (non void-filled) are float relative to ellipsoid
#SRTM-GL1 tiles are relative to EGM96
#https://lta.cr.usgs.gov/SRTM1Arc
#February 11-22, 2000

#Convert and adjust datum
#parallel -j 16 "gdalwarp -co COMPRESS=LZW -co TILED=YES -co BIGTIFF=IF_SAFER -overwrite -r cubic -t_srs EPSG:$epsg -dstnodata -32768 -tr 30 30 {} {.}_${epsg}.tif; dem_geoid --threads 1 --reverse-adjustment {.}_${epsg}.tif" ::: $fn_list
#Create vrt mosaic
#gdalbuildvrt -resolution highest -vrtnodata -32768 hma_srtm_gl1.vrt *_${epsg}-adj.tif

parallel -j 16 "gdalwarp $gdal_opt -overwrite -r cubic -t_srs \"$proj\" -dstnodata -32768 -tr 30 30 {} {.}_aea.tif" ::: $fn_list
fn_list=$(echo $fn_list | sed 's/.hgt/_aea.tif/g')
gdalbuildvrt nasadem_hgt_srtmOnly_R4_aea.vrt $fn_list 
