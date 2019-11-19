#!/bin/bash
#this script clips and polygonizes a reclassified normalized burn ratio raster
#this line is reprojecting a shapefile and converts it to a spatialite polygon which will be used to clip a raster
ogr2ogr -select CLIP_POLYGON_LAYER -t_srs EPSG:YOUR_CRS_EPSG -f SQLite projected_clip_polygon.sqlite CLIP_POLYGON.shp
#reprojecting and clipping a raster to the shapefile above 
gdalwarp -t_srs EPSG:28356 -cutline projected_clip_polygon.sqlite -cl CLIP_POLYGON Burn_ratio.tif Burn_proj.tif
#converting any raster cells less than 5 to the surrounding value.
#this cleans a lot of the small errors from the burn ratio calculation
gdal_sieve.py -st 5 Burn_proj.tif Burn_proj_clean.tif
#raster to polygon
#this method is far quicker than rasterToPolygons in R. Reduced the processing time from multiple hours to seconds.
gdal_polygonize.py Burn_proj_clean.tif fire_areas_gdal.shp
#removing intermediate files created in the process
rm Burn_proj_clean.tif Burn_proj.tif projected_clip_polygon.sqlite
