# TEST RUN - map of Perros-Guirec
# Christmas 2017 Map of Brittany
# By Lucas and Robyn

# required libraries:
req.libs = c("tidyverse", "osmdata", "sf", "rgeos", "maptools","PBSmapping")

# load them, install if needed:
new.libs = req.libs[!(req.libs %in% installed.packages()[, "Package"])]
if (length(new.libs)) install.packages(new.libs)
sapply(req.libs, require, character.only = TRUE)

#########################################################
#######                       GET THE MAP DATA                                #########
#########################################################

# let's build a map with a smaller test location
loc_name = "perros guirec, france"
getbb(loc_name)

# All road data: download location roads as sf (special features)
# thanks to http://strimas.com/r/tidy-sf/ for the tutorial on SF in R
# the value for roads in osm is highway.
# Import each road type as a separate object.
# For details, see: http://wiki.openstreetmap.org/wiki/Map_Features

# see all available values within the key highway
available_tags('highway')

# these are ordered by importance/size. see link above.
target_vals = c('motorway', 'trunk', 'primary',
	'secondary', 'tertiary', 'unclassified',
	'residential','service')

# however, the value is stored in the column "highway"! 
# note: polygons end up in the roads because of connected lines like roundabouts
loc_name %>%
		opq(bbox = .) %>%
		add_osm_feature(key = 'highway') %>%
		osmdata_sf() ->
all_roads_sfcollection
	
# see the data
ggplot() +
	geom_sf(data=all_roads_sfcollection$osm_lines, aes(color=highway)) +
	geom_sf(data=all_roads_sfcollection$osm_polygons, aes(color=highway), fill=NA) +
	coord_sf(crs = st_crs("+proj=utm +zone=30U +datum=WGS84"))
	
# Let's try to get the coastline
# @FIX: the following coast part needs to be updated for use with SF!

loc_name %>%
	opq(bbox = .) %>%
	add_osm_feature(key = 'natural', value = 'coastline') %>%
	osmdata_sf() ->
loc_coast_sf

# we want the coastline to be a polygon, but we will need a point for
# the lowerlefthand (ll) corner. Let's extract coordinates from perros-g:
loc_name %>%
	getbb() %>%
	.[,1] ->
ll

loc_coast_sf %>%
	.$osm_lines %>%
	# merge the 15 lines that make up the coast to one line:
	gLineMerge() %>%
	# make the lines a polygon
	SpatialLines2PolySet() %>%
	fortify %>%
	tbl_df %>%
	# just a hack for now, adding two points to make the poly a better shape
	rbind(.,c(NA,NA,NA,ll[1],ll[2]),
	c(NA,NA,NA,-3.39,ll[2])) ->
loc_coast_poly

# so the data we have now is:
# loc_coast_poly
all_roads_sfcollection

# we need to import classes of highways 1 by 1,
# so that we can have diff. line thicknesses
# see - # http://wiki.openstreetmap.org/wiki/Key:highway
# we also need water, perhaps railways..
# perhaps we also need to convert long/lat to UTMs

# let's plot this....

#########################################################
#####                                   PLOT & SAVE IMAGE                               ######
#########################################################

##---- SET OPTIONS ----##
# Final dimensions (in inches)
width_in = 24
height_in = 18

# margins (inches)
print_mar = 0.25

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

##---- BASE MAP----##
base_map = ggplot() + theme_minimalmap() #+
		#coord_equal(expand = FALSE) +
		# scale_y_continuous(breaks=myBreaks) +
		# scale_x_continuous(breaks=myBreaks)

# FINAL MAP, where we add the data:
base_map +
	# data:
	#geom_polygon(data=loc_coast_poly,aes(x=X,y=Y),fill=col_land)+
	#geom_path(data=loc_highway_lines,aes(x=long, y=lat, group=group),colour=col_road) +
	geom_sf(data=all_roads_sfcollection$osm_lines, aes(color=highway)) +
	geom_sf(data=all_roads_sfcollection$osm_polygons, aes(color=highway), fill=NA) +
	coord_sf(crs = st_crs("+proj=utm +zone=30U +datum=WGS84"))
	

	
	
	
# see how it looks as a png, with auto-selected dimensions for now:
# filename includes date and time
ggsave(filename=
	paste0("../output/perros_testmap_", format(Sys.time(), "%Y%m%d_%H%M"), ".png")
)
