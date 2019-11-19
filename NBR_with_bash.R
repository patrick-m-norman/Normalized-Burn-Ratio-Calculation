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


#pre burn NBR
O_SWIR <- raster('Pre_burn_short_wave_infrared.tiff')
O_NIR <- raster('Pre_burn_near_infrared.tiff') %>% resample(.,O_SWIR)

#calculating old normalized burn ratio
O_NBR <- (O_NIR-O_SWIR)/(O_NIR+O_SWIR)

#post burn NBR
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
#the values are predetermined burn severity values from https://wiki.landscapetoolbox.org/doku.php/remote_sensing_methods:normalized_burn_ratio
m <- c(-5.0, 0.1, 1,  0.1, 0.27, 2, 0.27, 0.66, 3, 0.66, 2, 4)
rclmat <- matrix(m, ncol=3, byrow=TRUE)
rc <- reclassify(Ratio, rclmat)
plot(rc)

#writing out the file to then put it into GDAL
writeRaster(rc, 'OUTPUT_BURN_RATIO.tif', overwrite=TRUE)
#-------------------------------------------------------------------------------------
#THIS IS WHERE YOU PERFORM THE SHELL SCRIPTING
#You'll need to get GDAL installed and working. Then in bash get
#to the folder where your files are located type
#bash GDAL_bash_processing.sh

#-------------------------------------------------------------------------------------
#then after the shell script finishes
library(tmaptools)
library(tmap)
library(plyr)
library(maps)
library(grid)

#reading back in the newly made polygon
burn_ratio_poly <- readOGR(".", layer = "fire_areas_gdal_out") 
#converting the burn severity to an integer
burn_ratio_poly$DN <- as.integer(burn_ratio_poly$DN)

#subsetting to get only the burnt areas
burn_areas_clean <- burn_ratio_poly[burn_ratio_poly$DN>2,] %>% 
  buffer(., width=0, dissolve=FALSE) #this part just cleans up the polygon if there are any errors that have occurred

#getting the severity back as a factor then revaluingthe DN to severity number
burn_areas_clean$Severity <- as.factor(burn_areas_clean$DN) %>%
  revalue(., c('3' ="Low", '4'="Moderate", '5'="High"))

#creating an area column of the data
burn_areas_clean$area_ha <- area(burn_areas_clean) / 10000

#creating a very basic map of the burn areas
tm_shape(back) + tm_raster() +
  tm_shape(burn_areas_clean) + 
  tm_fill(col = "Severity",palette = "OrRd") + 
  tm_borders() + 
  tm_scale_bar(position=c("left", "bottom")) +
  tm_compass(position = 'left')

#this will export the newly made normalized burn ratio shapefile
writeOGR(dsn= '.',burn_areas_clean, driver="ESRI Shapefile" , layer = 'OUTPUT_FILE_NAME')
