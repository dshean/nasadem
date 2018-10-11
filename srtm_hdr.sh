#! /bin/bash

#Generate hdr files for NASADEM products
#https://e4ftl01.cr.usgs.gov/provisional/MEaSUREs/NASADEM/

#See documentation for descriptions of different data products and extensions

#This hack because current GDAL SRTM driver doesn't read these data types
#http://www.gdal.org/frmt_various.html#SRTMHGT

fn=$1
echo $fn

fnbase=${fn%.*}

lat=$(echo $fn | cut -c 2-3)
lon=$(echo $fn | cut -c 5-7)
ew=$(echo $fn | cut -c 4)

#Deal with postive west vs positive east longitude systems
#Convert everything to positive east 
if [ "$ew" == "w" ] ; then
    lon=-${lon}
fi

hdr=${fnbase}.hdr

#Get extension
#After extracting zip files, yielding .hgt files
ext=${fn#*.}
#When working with .hgt.zip files
#ext=$(echo ${fn#*.} | awk -F'.' '{print $1}')

if [ "$ext" == "hgt" ] ; then
    nbits=16
    dtype=signedint
    ndv=-32768
elif [ "$ext" == "srtmOnly.hgt" ] ; then
    nbits=32
    dtype=float
    ndv=-32768
elif [ "$ext" == "img" ] ; then
    nbits=8
    dtype=byte
    ndv=0
elif [ "$ext" == "err" ] ; then
    nbits=16
    dtype=unsignedint
    #Note that there may be an issue with gdalwarp using dstnodata of 0 without an explicit value
    #Doc says -32768, but haven't found any pixels with this value
    #Lots of 32768 values, indicating clipped error values
    ndv=32768
elif [ "$ext" == "num" ] ; then
    nbits=8
    dtype=byte
    ndv=255
fi

cellsize=0.0002777777777777

#The SRTM tile coordinates are for center of lower left pixel
#Need to adjust for ESRI hdr data model, lower left corner of lower left pixel
#0.000138888888889
lon=$(echo "scale=8; $lon - ($cellsize/2.)" | bc)
lat=$(echo "scale=8; $lat - ($cellsize/2.)" | bc)

echo -n > $hdr
echo "ncols 3601" >> $hdr
echo "nrows 3601" >> $hdr
echo "cellsize $cellsize" >> $hdr
echo "xllcorner $lon" >> $hdr 
echo "yllcorner $lat" >> $hdr 
echo "nodata_value $ndv" >> $hdr
echo "nbits $nbits" >> $hdr
echo "pixeltype $dtype" >> $hdr
echo "byteorder msbfirst" >> $hdr

#ln -sf $fn ${fnbase}.raw 

echo 'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]]' > ${fnbase}.prj
