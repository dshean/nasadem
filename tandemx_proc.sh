#! /bin/bash

#Download and process TanDEM-X 90-m products

#Save list by cmd-click and downloading list
#https://download.geoservice.dlr.de/TDM90/

#Set these
#uname=email@domain.edu
#Quotes required for special characters in pw
#pw=\''passwd'\'
#parallel -j 64 "wget --auth-no-challenge --user=$uname --password=$pw -nc {}" < TDM90-url-list.txt
#parallel --progress 'unzip {}' ::: *.zip

function proc_lyr() {
    gdal_opt="-co COMPRESS=LZW -co TILED=YES -co BIGTIFF=IF_SAFER"
    #HMA
    site='hma'
    proj='+proj=aea +lat_1=25 +lat_2=47 +lat_0=36 +lon_0=85 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs '

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

export -f proc_lyr
parallel "proc_lyr {}" ::: DEM HEM AMP

#Create shaded relief map for DEM
site='hma'
hs.sh TDM1_DEM_90m_${site}_DEM_aea.tif
gdaladdo_ro.sh TDM1_DEM_90m_${site}_DEM_aea_hs_az*.tif
