# Normalized-Burn-Ratio-Calculation
These R and Bash scripts process pre and post fire satellite images to calculate a normalized burn ratio to evaluate the area and burn severity
of bushfires and wildfires. When using Sentinel 2 data this can be calculated to a resolution of 20m x 20m.

Satellite data which can be used includes but is not limited to Landsat 8 or Sentinel 2 data. These can be sourced from
https://glovis.usgs.gov/ and https://scihub.copernicus.eu/dhus/#/home respectively. 
More specifically to calculate this data the pre and post fire near infrared and short wave infrared bands will be needed. 

Both R scripts perform exactly the same calculation and produce the same output. The NBR_totally_in_R script performs the whole process
entirely within R where the NBR_with_bash script works in conjunction with the GDAL_bash_processing script. When dealing with very small areas
(under 5km x 5km), the NBR_totally_in_R script will perform the calculations quickly. Anything above this size/ if you are comfortable with
shell scripting, I recommend using the NBR_with_bash script with GDAL_bash_processing, as the raster projection and polygonize functions will
take seconds on GDAL and hours on R. 

Apart from the satellite data, the only other input file required for these scripts is an existing vegetation layer

The resulting output will include a tif and a shapefile of the burn ratio, of which the shapefile will contain an area calculation to 
assess, provided a projected coordinate reference system has been used. This can be used to establish the total area each of the severity of
burns. Also included in the script is a very basic map showing the shapefile output.

