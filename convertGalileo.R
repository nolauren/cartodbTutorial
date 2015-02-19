#!/usr/bin/env Rscript

require("XML")
require("iotools")
require("fasttime")

# Read in the data
x = xmlRoot(xmlParse("data/galileo.kml"))
coords = toString.XMLNode(x[[1]][[4]][[4]][[2]][[1]])
coords = mstrsplit(charToRaw(coords), sep=",",ncol=3)
coords = coords[-c(1,nrow(coords)),]
temp = strsplit(toString.XMLNode(x[[1]][[4]][[5]]),"\n")[[1]]
dt = fasttime::fastPOSIXct(substr(temp[grep("<when>",temp)],9L,27L))
data = data.frame(lat=as.numeric(coords[,2]), lon=as.numeric(coords[,1]),
                  alt=as.numeric(coords[,3]), dt=dt, ts=as.integer(dt) )

write.csv(data, "data/galileo.csv", quote=FALSE, row.names=FALSE)