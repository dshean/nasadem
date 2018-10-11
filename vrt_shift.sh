#! /bin/bash

#When building GDAL vrt from ESRI grid, the geotransform is incorrect
#Off by 1 pixel in x and y
#Need to shift -30 m x and +30 m y

vrt_fn=$1
gt_xml=$(grep GeoTransform $vrt_fn)
xo=$(echo $gt_xml | awk -F'[ <>,]' '{print $4}')
dx=$(echo $gt_xml | awk -F'[ <>,]' '{print $6}')
yo=$(echo $gt_xml | awk -F'[ <>,]' '{print $10}')
dy=$(echo $gt_xml | awk -F'[ <>,]' '{print $14}')
x1=$(python -c "i=float($xo)-float($dx) ; print(i)")
y1=$(python -c "i=float($yo)-float($dy) ; print(i)")
echo $xo $yo
echo $x1 $y1
cat $vrt_fn | sed -e "s/$xo/$x1/" -e "s/$yo/$y1/" > ${vrt_fn%.*}_shift.vrt 
