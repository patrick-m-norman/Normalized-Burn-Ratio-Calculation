#Calculating Normalized Burn Ratio for an area
#Often this calculation is used with Landsat 8 data, though its resolution isn't as fine as Sentinel 2
#Sentinel 2 data has a resolution of 10m for some bands and 20 for others.
setwd("YOUR_WORK_DIRECTORY")
library(tiff)
library(raster)
library(rgdal)
library(rgeos)
library(sp)
library(magrittr)
library(tmaptools)
library(tmap)
library(plyr)
library(maps)
library(grid)


#old NBR
O_SWIR <- raster('Pre_burn_short_wave_infrared.tiff')
O_NIR <- raster('Pre_burn_near_infrared.tiff') %>% resample(.,O_SWIR)

#calculating old normalized burn ratio
O_NBR <- (O_NIR-O_SWIR)/(O_NIR+O_SWIR)

#New NBR
N_SWIR <- raster('Post_burn_short_wave_infrared.tiff')
N_NIR <- raster('Post_burn_near_infrared.tiff') %>% resample(.,N_SWIR)


#calculating new normalized burn ratio
N_NBR <- (N_NIR-N_SWIR)/(N_NIR+N_SWIR)


#the difference between the old and the new. This is the output that can be used for 
Ratio <- O_NBR - N_NBR
plot(Ratio)

#removing the already processed layers out of memory
rm(O_SWIR,O_NIR,O_NBR,N_NIR,N_NBR,N_SWIR)

#reclassify the NBR
#this works like min, 1st cut = 1 and 1st cut to max = 2 and so on
#the values are predetermined burn severities values from https://wiki.landscapetoolbox.org/doku.php/remote_sensing_methods:normalized_burn_ratio
m <- c(-5.0, 0.1, 1,  0.1, 0.27, 2, 0.27, 0.66, 3, 0.66, 2, 4)
rclmat <- matrix(m, ncol=3, byrow=TRUE)
rc <- reclassify(Ratio, rclmat)
plot(rc)

#writing out the file to then put it into GDAL
writeRaster(rc, 'Burn_ratio.tif', overwrite=TRUE)
#-------------------------------------------------------------------------------------------------------------------------
#THIS NEXT PART READS IN A VEGETATION LAYER TO CLIP THEN PROJECTS AND CLIPS THE RASTER, POLYGONIZES IT THEN CLEANS IT.
#Now read in the vegetation layer and project it to your location in proj4string
vegetation <- readOGR(".", layer = "vegetation") %>%
  spTransform(., CRS('YOUR_PROJECTED_COORDINATE_SYSTEM'))

#Clip the burn ratio to you polygon
burn_ratio_clip <- projectRaster(rc, crs='YOUR_PROJECTED_COORDINATE_SYSTEM') %>%
  crop(., vegetation)

#Now to polygonize the raster. This will take a while if the raster is large!!!
burn_ratio_poly <- rasterToPolygons(burn_ratio_clip,dissolve = TRUE)
plot(burn_ratio_poly)
  
#converting the burn severity to an integer
burn_ratio_poly$layer <- as.integer(burn_ratio_poly$layer)

#subsetting to get only the burnt areas
burn_areas_clean <- burn_ratio_poly[burn_ratio_poly$layer>1,] %>% 
  buffer(., width=0, dissolve=FALSE) #this part just cleans up the polygon if there are any errors that have occurred

#getting the severity back as a factor then revaluingthe DN to severity number
burn_areas_clean$Severity <- as.factor(burn_areas_clean$layer) %>%
  revalue(., c('2' ="Low", '3'="Moderate", '4'="High"))

#creating an area column of the data
burn_areas_clean$area_ha <- area(burn_areas_clean) / 10000
#-----------------------------------------------------------------------------------------------------------------------------
#creating a very basic map of the burn areas
tm_shape(burn_areas_clean) + 
  tm_fill(col = "Severity",palette = "OrRd") + 
  tm_borders() + 
  tm_scale_bar(position=c("left", "bottom")) +
  tm_compass(position = 'left')

#-----------------------------------------------------------------------------------------------------------------------------

#Finally this will export the newly made normalized burn ratio shapefile
writeOGR(dsn= '.',burn_areas_clean, driver="ESRI Shapefile" , layer = 'OUTPUT_FILE_NAME')
