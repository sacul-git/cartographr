# TEST RUN - map of Perros-Guirec
# Christmas 2017 Map of Brittany
# By Lucas and Robyn

# required libraries:
req.libs = c("tidyverse", "osmdata", "sf", "rgeos", "maptools","PBSmapping")

# load them, install if needed:
new.libs = req.libs[!(req.libs %in% installed.packages()[, "Package"])]
if (length(new.libs)) install.packages(new.libs)
sapply(req.libs, require, character.only = TRUE)

# note: need ggplot2 version  2.2.1.9000 or higher to use sf_geom. May need to install development version:
# devtools::install_github("tidyverse/ggplot2")

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

## ROADS
# see all available values within the key highway
available_tags('highway')

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
		coord_sf(crs = st_crs("+proj=utm +zone=30U +datum=WGS84"))
		
### COASTLINE / LAND MASS
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

## RAILWAY
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
		
# WATER

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

# limits of mapping region (in long and lat)
lims = getbb(loc_name) %>% t %>% as.data.frame

# issue: when using 	#crs = st_crs("+proj=utm +zone=30U +datum=WGS84 +units=km"), in coord_sf, lines disappear...
# issue2: with long/lat, scale_x_continuous(breaks=myBreaks) gives error - invalid 'type' (closure) of argument

ggplot() + theme_minimalmap() +
	geom_sf(data=coast_gg, color=NA, fill=col_land)+
	geom_sf(data=waterlines_gg, color=col_water, size=0.7)+
	geom_sf(data=waterpolys_gg, fill=col_water, color=NA)+
	geom_sf(data=roads_gg, color=col_road, size=0.001) +
	coord_sf(expand=FALSE, xlim = lims[,1], ylim=lims[,2])
	# missing rails, diff road sizes, diff highway color...

	
# see how it looks as a png, with auto-selected dimensions for now:
# filename includes date and time
ggsave(filename=
	paste0("../output/perros_testmap_", format(Sys.time(), "%Y%m%d_%H%M"), ".png")
)
