# TEST RUN - map of Perros-Guirec
# Christmas 2017 Map of Brittany
# By Lucas and Robyn

# required libraries:
req.libs = c("tidyverse", "osmdata", "sf", "rgeos", "maptools","PBSmapping", "rgdal")

# load them, install if needed:
new.libs = req.libs[!(req.libs %in% installed.packages()[, "Package"])]
if (length(new.libs)) install.packages(new.libs)
sapply(req.libs, require, character.only = TRUE, quietly=TRUE)

# note: need ggplot2 version  2.2.1.9000 or higher to use sf_geom. May need to install development version:
# devtools::install_github("tidyverse/ggplot2")

#================#
##################
#  GET MAP DATA  #
##################
#================#

# let's build a map with a small test location:
loc_name = "perros guirec, france"
getbb(loc_name)

# All road data: download location roads as sf (special features)
# thanks to http://strimas.com/r/tidy-sf/ for the tutorial on SF in R
# the value for roads in osm is highway.
# Import each road type as a separate object.
# For details, see: http://wiki.openstreetmap.org/wiki/Map_Features
# Ex: see all available values within the key highway
# available_tags('highway')

#================#
#      ROADS     #
#================#
# these are ordered by importance/size. see link above.
target_vals = c('motorway', 'trunk', 'primary',
	'secondary', 'tertiary', 'unclassified',
	'residential','service')

# however, the value is stored in the column "highway" - YAY!
loc_name %>%
		opq(bbox = .) %>%
		add_osm_feature(key = 'highway') %>%
		osmdata_sf() ->
roads_sfc

# extract the crs for later use...
myCrs = roads_sfc$osm_lines %>% st_crs

# in this example, roads are stored as lines and polygons.
# polygons end up in the roads because of connected lines like roundabouts.
# let's combine these two categories and get rid of excess columns
rbind(roads_sfc$osm_lines, roads_sfc$osm_polygons) %>%
	select(highway) -> # geometry stays!
roads_gg
# roads ready for ggplot

# have a look
roads_gg %>%
	ggplot(.) +
		geom_sf(size=1, fill=NA, aes(color=highway)) +
		coord_sf(crs = "+proj=utm +zone=30U +datum=WGS84")

#================#
#   COASTLINE &  #
#   LANDMASS     #
#================#

# Let's try to get the coastline, seems to work best with admin_level 2 (federal boundaries...)
loc_name %>%
	opq(bbox = .) %>%
	add_osm_feature(key = 'admin_level', value = '2') %>%
	osmdata_sf() ->
admin2_sfc

# the osm_multilines for this seems to work well, but we need to make it a polygon...
admin2_sfc$osm_multilines %>%
	st_line_merge %>%
	st_cast(x=., to="MULTIPOLYGON") ->
coast_gg
# @FIX: we may need to add points to define the end shape of the polygon, wait until we are plotting britanny to see fix...

# have a look
ggplot() +
	geom_sf(data = coast_gg, color="blue", fill="pink") +
	coord_sf(crs = st_crs("+proj=utm +zone=30U +datum=WGS84"))

#================#
#    RAILWAYS    #
#================#

loc_name %>%
		opq(bbox = .) %>%
		add_osm_feature(key = 'railway') %>%
		osmdata_sf() ->
rails_sfc

rails_sfc$osm_lines %>%
		select(railway) ->
rails_gg

ggplot() +
	geom_sf(data=roads_gg, size=0.8, fill=NA, color='grey', alpha=0.8) +
	geom_sf(data=rails_sfc$osm_lines, size=1.1, fill=NA, color='black') +
	coord_sf(crs = st_crs("+proj=utm +zone=30U +datum=WGS84"))

#================#
#      WATER     #
#================#

loc_name %>%
		opq(bbox = .) %>%
		add_osm_feature(key = 'natural', value="water") %>%
		osmdata_sf() ->
water_sfc

water_sfc$osm_polygons %>%
	select(water) ->
waterpolys_gg

loc_name %>%
	opq(bbox = .) %>%
	add_osm_feature(key = 'waterway') %>%
	osmdata_sf() ->
waterways_sfc

rbind(
	waterways_sfc$osm_multilines %>% select(water = waterway),
	waterways_sfc$osm_lines %>% select(water=waterway)) ->
waterlines_gg

# so the data we have now is:
# loc_coast_poly
roads_gg
coast_gg # aka land
rails_gg
waterlines_gg
waterpolys_gg
# let's plot this....

#================#
##################
#  PLOT & SAVE   #
##################
#================#

# get the CRS from another sf object
crsNorm = st_crs(waterpolys_gg)$proj4string
# choose a projection that we will attempt to use to get a 24x18 image
myProj = "+proj=utm +zone=30U +datum=WGS84"

#================#
#  SET OPTIONS   #
#================#

# Final dimensions (in inches)
width_in = 24
height_in = 18

# margins (inches)
print_mar = 0.5

# desired long/lat sfor map of Britanny (chosen manually on osm website):
xmin = -5.702
xmax = -0.890
ymax = 49.038
# need ymin, must project to UTM first...

xy = cbind(c(xmin, xmax), c(ymax, ymax))
xy_utm = rgdal::project(xy,myProj)

xmin_utm = xy_utm[1,1]
xmax_utm = xy_utm[2,1]
ymax_utm = xy_utm[2,2]

height_utm = ((xmax_utm-xmin_utm)/width_in)*height_in
ymin_utm = ymax_utm - height_utm
xy_utm[1,2] = ymin_utm

# britanny bounding box:
xy_utm %>%
	rgdal::project(myProj, inv=TRUE) %>%
	`colnames<-`(c("x","y")) %>%
	`rownames<-`(c("min","max")) ->
bb_brit

loc_name %>%
	getbb() %>%
	t ->
bb_loc

# a little function to take a bounding box in the format above, and make it coordinates for a polygon
bb_to_poly = function(bb,minrow="min",maxrow="max",xcol="x",ycol="y",crs = crsNorm, name){
	c(	bb[minrow,xcol],bb[minrow,ycol],
		bb[minrow,xcol],bb[maxrow,ycol],
		bb[maxrow,xcol],bb[maxrow,ycol],
		bb[maxrow,xcol],bb[minrow,ycol],
		bb[minrow,xcol],bb[minrow,ycol]) %>%
	matrix(., ncol=2, byrow=TRUE) %>%
	list %>%
	st_polygon %>%
	st_sfc	%>%
	st_sf(name=name, geometry=.) %>%
	st_set_crs(crs)
}

bb_loc_sf = bb_to_poly(bb=bb_loc, name="peros")
bb_brit_sf = bb_to_poly(bb=bb_brit, name="brit")

# grid degrees (if we do grids)
# change if we convert to UTM
grid_degrees = 0.01

# Colours
col_water = "#EEEEEE"
col_road = "#424242"
col_freeway = "#0A0A0A"
col_land = "#FFFFFF"
col_border = "#e8e5e5"
col_gridline = "#e8e5e5"

##---- CUSTOM MAP THEME ----##

theme_minimalmap = function(
	# arguments (set border and gridline to NA if hidden!)
	water=col_water,border=col_border,gridline=col_gridline,mar=print_mar
	){
		# ggplot theme elements
		theme(
			# hide elements
			axis.ticks = element_blank(),
			axis.title = element_blank(),
			axis.line = element_blank(),
			plot.title = element_blank(),
			axis.text = element_blank(),
			legend.position = "none",
			# margin and border
			panel.border = element_rect(fill = NA, color = border),
			plot.margin	 = margin(mar, mar, mar, mar, "in"),
			# background colors
			plot.background = element_rect(fill = "white", color = NA),
			panel.background = element_rect(fill = water, color = NA),
			# grid lines
			panel.grid.minor =  element_blank(),
			panel.grid.major = element_line(color = gridline, size = 0.3))
}

# function to make custom gridline breaks:
myBreaks = function(x){
	breaks = seq(from=min(x),to=max(x),by=grid_degrees)
	names(breaks) = attr(breaks,"labels")
	breaks
}

# limits of mapping region (in long and lat)
# lims = getbb(loc_name) %>% t %>% as.data.frame

# issue2: with long/lat, scale_x_continuous(breaks=myBreaks) gives error - invalid 'type' (closure) of argument

# britanny layout test!
ggplot() + theme_minimalmap() +
	geom_sf(data=bb_brit_sf, col=NA, fill="black") +
	geom_sf(data=bb_loc_sf, col=NA, fill="red") +
	geom_sf(data=coast_gg, color=NA, fill="white") +
	geom_sf(data=roads_gg, color="blue", fill=NA, size=0.01) +
	coord_sf(expand=FALSE, xlim = bb_brit[,1], ylim=bb_brit[,2])

# ggsave(filename=
	# paste0("../output/perros_testmap_", format(Sys.time(), "%Y%m%d_%H%M"), ".pdf"),
	# width = width_in, height = height_in, units = "in"
# )


# continue refining the map/
ggplot() + theme_minimalmap() +
	geom_sf(data=bb_brit_sf, col=NA, fill=col_water) +
	geom_sf(data=coast_gg, color=NA, fill=col_land)+
	geom_sf(data=waterlines_gg, color=col_water, size=0.7)+
	geom_sf(data=waterpolys_gg, fill=col_water, color=NA)+
	geom_sf(data=roads_gg, color=col_road, size=0.01) +
	coord_sf(expand=FALSE, xlim = bb_brit[,1], ylim=bb_brit[,2])
	# missing rails, diff road sizes, diff highway color...


# see how it looks as a png, with auto-selected dimensions for now:
# filename includes date and time
ggsave(filename=
	paste0("../output/perros_testmap_", format(Sys.time(), "%Y%m%d_%H%M"), ".pdf"),
	width = width_in, height = height_in, units = "in"
)
