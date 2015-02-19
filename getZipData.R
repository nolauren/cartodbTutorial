#!/usr/bin/env Rscript

require("maptools")

system("curl -O http://www2.census.gov/geo/tiger/TIGER2010DP1/ZCTA_2010Census_DP1.zip")
unzip("ZCTA_2010Census_DP1.zip")

zip = readShapeSpatial("ZCTA_2010Census_DP1.shp")
lat = as.numeric(as.character(zip@data$INTPTLAT10))
lon = as.numeric(as.character(zip@data$INTPTLON10))

index = which(lat > 40.667809 & lat < 41.344754 &
              lon < -72.864870 & lon > -74.036271)
z = zip[index,]

system("mkdir -p lt_zips")
writeSpatialShape(z, "lt_zips/lt_zips")
system("gzip lt_zips")
system("mv lt_zips.zip data")