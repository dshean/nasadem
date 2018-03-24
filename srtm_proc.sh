#! /bin/bash

#Wrapper to fetch and process NASADEM SRTM products for regional mosaics

#NASADEM hgt_srtmOnly_R4 (non void-filled) are float relative to ellipsoid
#SRTM-GL1 tiles are relative to EGM96
#https://lta.cr.usgs.gov/SRTM1Arc
#February 11-22, 2000

#For provisional NASADEM products, need NASA Earthdata account
uname=dshean
#Need to hardcode password if using GNU parallel to fetch (recommended)
pw=''

gdal_opt="-co COMPRESS=LZW -co TILED=YES -co BIGTIFF=IF_SAFER"

#CONUS
#site='conus'
#proj='+proj=aea +lat_1=36 +lat_2=49 +lat_0=43 +lon_0=-115 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs '

#HMA
site='hma'
proj='+proj=aea +lat_1=25 +lat_2=47 +lat_0=36 +lon_0=85 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs '

if [ ! -d $site ] ; then
    mkdir $site
fi
cd $site

#productdir_list='hgt_srtmOnly hgt_merge err img'
productdir_list='hgt_srtmOnly'

for productdir in $productdir_list
do
    if ["$productdir" == 'hgt_merge'] ; then
        ext_list='hgt num'
    else if ["$productdir" == 'hgt_srtmOnly_R4'] ; then
        ext_list='srtmOnly.hgt'
    else if ["$productdir" == 'img_comb'] ; then
        #ext_list='img img.num'
        ext_list='img'
    else if ["$productdir" == 'err_I2'] ; then
        ext_list='err'
    else
        echo "Invalid product directory"
        exit
    fi

    if [ ! -d $productdir] ; then
        mkdir $productdir
    fi
    cd $productdir

    for ext in $ext_list
    do
        #Generate a text file containing url for all tiles
        #Edit srtm_tilelist.py, modify lat/lon bounds 
        urllist=${site}_nasadem_tilelist_${productdir}_${ext}.txt
        echo -n > $urllist
        srtm_tilelist.py $site $productdir >> $urllist 

        url_zip_list=$(cat $urllist | awk -F'/' '{print $NF}')
        fn_list=$(ls *${ext}.zip)

        echo -n > ${urllist%.*}_missing.txt
        for i in $url_zip_list
        do
            if ! echo $fn_list | grep -q $i ; then
                grep $i $urllist >> ${urllist%.*}_missing.txt
            fi
        done

        if [ ! -z "$pw" ] ; then 
            #Parallel wget
            cat ${urllist%.*}_missing.txt | parallel --delay 1 -j 16 --progress "wget --user $uname --password $pw -nc -q {}"
        else
            #Serial wget 
            wget --user $uname --ask-password -nc -i $urllist
        fi

        #Unzip tiles
        fn_list_to_unzip=''
        for i in *${ext}.zip
        do
            if [ ! -e ${i%.*} ] ; then 
                fn_list_to_unzip+=" $i"
            fi
        done
        parallel 'unzip {} -d {.}' ::: $fn_list_to_unzip

        #Generate hdr and prj sidecar files
        fn_list=$(ls *.${ext})
        parallel 'srtm_hdr.sh {}' ::: $fn_list

        #Build mosaic in original WGS84 coordinates
        gdalbuildvrt ${site}_nasadem_${ext}.vrt $fn_list
        #gdaladdo_ro.sh ${site}_nasadem_${ext}.vrt
        #gdal_translate $gdal_opt ${site}_nasadem_${ext}.vrt ${site}_nasadem_${ext}.tif
        #gdalwarp -overwrite $gdal_opt -r cubic -t_srs "$proj" -tr 30 30 nasadem_${ext}.vrt nasadem_${ext}_30m.tif

        cd ..
    done

exit

#Mask elevation values where err >= 32769
productdir=hgt_srtmOnly_R4
ext=srtmOnly.hgt
parallel --delay 0.1 'srtm_errmask.py {} err/{/.}.err' ::: $productdir/*.${ext}
cd $productdir 
gdalbuildvrt -o ${site}_nasadem_${productdir}_lt5m_err.vrt *{ext}_lt5m_err.tif
cd ..

#Remove EGM96 offset from void-filled hgt files
productdir=hgt_merge
ext=hgt
parallel --delay 0.1 'dem_geoid --threads 1 --reverse-adjustment {}' ::: $productdir/*.${ext}
cd $productdir 
gdalbuildvrt -o ${site}_nasadem_${productdir}_adj.vrt *{ext}-adj.tif
cd ..

parallel -j 16 "gdalwarp $gdal_opt -overwrite -r cubic -t_srs \"$proj\" -dstnodata -32768 -tr 30 30 {} {.}_aea.tif" ::: $fn_list
fn_list=$(echo $fn_list | sed 's/.hgt/_aea.tif/g')
gdalbuildvrt nasadem_hgt_srtmOnly_R4_aea.vrt $fn_list 
