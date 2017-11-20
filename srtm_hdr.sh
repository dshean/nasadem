#! /bin/bash

#Generate hdr files for NASADEM products
#https://e4ftl01.cr.usgs.gov/provisional/MEaSUREs/NASADEM/

#This hack because current GDAL SRTM driver doesn't read these data types
#http://www.gdal.org/frmt_various.html#SRTMHGT

fn=$1
echo $fn

fnbase=${fn%.*}

lat=$(echo $fn | cut -c 2-3)
lon=$(echo $fn | cut -c 5-7)
ew=$(echo $fn | cut -c 4)
if [ "$ew" == "w" ] ; then
    lon=-${lon}
fi

hdr=${fnbase}.hdr

#Get extension
#After extracting zip files, yielding .hgt files
ext=${fn##*.}
#When working with .hgt.zip files
#ext=$(echo ${fn#*.} | awk -F'.' '{print $1}')

if [ "$ext" == "hgt" ] ; then
    nbits=32
    dtype=float
    ndv=-32768.0
elif [ "$ext" == "img" ] ; then
    nbits=8
    dtype=byte
    ndv=0
elif [ "$ext" == "err" ] ; then
    nbits=16
    dtype=unsignedint
    ndv=0
    #NOTE, should also add 32769 here
fi

echo -n > $hdr
echo "ncols 3601" >> $hdr
echo "nrows 3601" >> $hdr
echo "cellsize 0.00027770063871" >> $hdr
echo "xllcorner $lon" >> $hdr 
echo "yllcorner $lat" >> $hdr 
echo "nodata_value $ndv" >> $hdr
echo "nbits $nbits" >> $hdr
echo "pixeltype $dtype" >> $hdr
echo "byteorder msbfirst" >> $hdr

#ln -sf $fn ${fnbase}.raw 

echo 'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]]' > ${fnbase}.prj
