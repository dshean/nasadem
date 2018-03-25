#! /bin/bash

#Wrapper to fetch and process NASADEM SRTM products for regional mosaics

#SRTM collection dates: February 11-22, 2000

#hgt_srtmOnly_R4 (non void-filled) tiles are float relative to ellipsoid
#hgt_merge tiles are Int16 relative to EGM96

topdir=/nobackup/deshean/data/nasadem
if [ ! -d $topdir ] ; then
    mkdir $topdir
fi
#lfs setstripe -c 64 $topdir
cd $topdir

#For provisional NASADEM products, need NASA Earthdata account
uname=''
#Need to hardcode password if using GNU parallel to fetch (recommended)
#Make sure to use hard quotes if pw contains special characters
#pw=\''pw'\'
pw=''

#Scripts in repo must be in PATH, or specify here
srcdir=~/src/nasadem

gdal_opt="-co COMPRESS=LZW -co TILED=YES -co BIGTIFF=IF_SAFER"

#CONUS
site='conus'
proj='+proj=aea +lat_1=36 +lat_2=49 +lat_0=43 +lon_0=-115 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs '

#HMA
#site='hma'
#proj='+proj=aea +lat_1=25 +lat_2=47 +lat_0=36 +lon_0=85 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs '

if [ ! -d $site ] ; then
    mkdir $site
fi
cd $site

#This defines the products to download and process
productdir_list='hgt_srtmOnly_R4 err_I2 img_comb hgt_merge'

#Filter, adjust vertical datum and reproject
$srcdir/srtm_post.sh $site "$proj"

exit

for productdir in $productdir_list
do
    echo
    if [ "$productdir" == 'hgt_merge' ] ; then
        ext_list='hgt num'
    elif [ "$productdir" == 'hgt_srtmOnly_R4' ] ; then
        ext_list='srtmOnly.hgt'
    elif [ "$productdir" == 'img_comb' ] ; then
        #ext_list='img img.num'
        ext_list='img'
    elif [ "$productdir" == 'err_I2' ] ; then
        ext_list='err'
    else
        echo "Invalid product directory"
        exit
    fi

    if [ ! -d $productdir ] ; then
        mkdir $productdir
    fi
    cd $productdir

    for ext in $ext_list
    do
        #Create a subdir, so we avoid overwriting .hdr files for products with multiple file extensions
        if [ ! -d $ext ] ; then
            mkdir $ext
        fi
        cd $ext
        #Generate a text file containing url for all tiles
        #Edit srtm_tilelist.py, modify lat/lon bounds 
        urllist=${site}_nasadem_tilelist_${productdir}_${ext}.txt
        echo -n > $urllist
        $srcdir/srtm_tilelist.py $site $productdir $ext >> $urllist 
        nf=$(wc -l $urllist)
        echo "Total tile count: $nf"

        url_zip_list=$(cat $urllist | awk -F'/' '{print $NF}')
        fn_list=$(ls *${ext}.zip)

        echo -n > ${urllist%.*}_missing.txt
        for i in $url_zip_list
        do
            if ! echo $fn_list | grep -q $i ; then
                grep $i $urllist >> ${urllist%.*}_missing.txt
            fi
        done
        nf=$(wc -l ${urllist%.*}_missing.txt)
        echo "Missing tile count: $nf"

        if [ ! -z "$pw" ] ; then 
            #Parallel wget
            cat ${urllist%.*}_missing.txt | parallel --verbose --delay 1 -j 16 --progress "wget --user $uname --password $pw -nc -q {}"
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

        if [ ! -z "$fn_list_to_unzip" ] ; then 
            nf=$(echo $fn_list_to_unzip | wc -w)
            echo "Unzipped tile count: $nf"
            parallel --progress 'unzip {} {.}' ::: $fn_list_to_unzip
        fi

        #Generate hdr and prj sidecar files
        echo "Creating hdr and prj files"
        fn_list=$(ls *.${ext})
        parallel "$srcdir/srtm_hdr.sh {}" ::: $fn_list

        #Build mosaic in original WGS84 coordinates
        if [ ! -e ${site}_nasadem_${productdir}_${ext}.vrt ] ; then
            gdalbuildvrt ${site}_nasadem_${productdir}_${ext}.vrt $fn_list
            #gdaladdo_ro.sh ${site}_nasadem_${ext}.vrt
            #gdal_translate $gdal_opt ${site}_nasadem_${ext}.vrt ${site}_nasadem_${ext}.tif
            #gdalwarp -overwrite $gdal_opt -r cubic -t_srs "$proj" -tr 30 30 nasadem_${ext}.vrt nasadem_${ext}_30m.tif
        fi
        cd ..
    done
    cd ..
done

#Filter, adjust vertical datum and reproject
$srcdir/srtm_post.sh $site "$proj"
