#! /bin/bash

#Download and process TanDEM-X 90-m products

#Save list by cmd-click and downloading list
#https://download.geoservice.dlr.de/TDM90/

srcdir=~/src/nasadem

#Download

url_list=$1
#url_list=TDM90-url-list.txt
#Set username and password 
uname=''
#uname=email@domain.edu
#Quotes required for special characters in pw
pw=''
#pw=\''passwd'\'

#parallel --progress -j 64 "wget --auth-no-challenge --user=$uname --password=$pw -nc {}" < $url_list
#parallel --progress 'unzip {}' ::: *.zip

#Process

#export site='conus'
#export proj='+proj=aea +lat_1=36 +lat_2=49 +lat_0=43 +lon_0=-115 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs '
export site='hma'
export proj='+proj=aea +lat_1=25 +lat_2=47 +lat_0=36 +lon_0=85 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs '

function proc_lyr() {
    gdal_opt="-co COMPRESS=LZW -co TILED=YES -co BIGTIFF=IF_SAFER"

    lyr=$1
    lyr_list=$(ls */*/*$lyr.tif)
    vrt=TDM1_DEM_90m_${site}_${lyr}.vrt
    gdalbuildvrt -srcnodata -32767 -vrtnodata -32767 $vrt $lyr_list
    #Tried to avoid converting full-res tif, but overviews didn't work
    #gdalwarp -of VRT -overwrite -dstnodata -32767 -r cubic -tr 90 90 -t_srs "$proj" $gdal_opt $vrt ${vrt%.*}_aea.vrt
    #vrt=${vrt%.*}_aea.vrt
    #gdaladdo_ro.sh $vrt 
    gdalwarp -overwrite -dstnodata -32767 -r cubic -tr 90 90 -t_srs "$proj" $gdal_opt $vrt ${vrt%.*}_aea.tif
    gdaladdo_ro.sh ${vrt%.*}_aea.tif
}

#Mask DEM files using err products
max_err=1.5
parallel --progress "$srcdir/dem_errmask.py {}/DEM/*DEM.tif {}/AUXFILES/*HEM.tif $max_err" ::: TDM1_DEM*_C

export -f proc_lyr
#ext_list="DEM DEM_lt${max_err}m_err HEM AMP"
ext_list="DEM_lt${max_err}m_err"
parallel --progress "proc_lyr {}" ::: $ext_list

#Create shaded relief map for DEM
hs.sh TDM1_DEM_90m_${site}_DEM_aea.tif TDM1_DEM_90m_${site}_DEM_lt${max_err}m_err_aea.tif
gdaladdo_ro.sh TDM1_DEM_90m_${site}_DEM_aea_hs_az*.tif TDM1_DEM_90m_${site}_DEM_lt${max_err}m_err_aea_hs_az*.tif
