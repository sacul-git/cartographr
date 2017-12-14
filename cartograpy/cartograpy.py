'''
CARTOGRAPY: A script for making pretty maps in a python2 environment. Created by Robyn and Lucas.

!!First steps first!! Make sure to change the current working directory to the proper place!

For details on individual tags:
    http://wiki.openstreetmap.org/wiki/Map_Features
For details on how to make Polygons (or at least a starting point), see comments at bottom of script. Although honestly, I didn't get very far on that...
'''

import overpy
from mpl_toolkits.basemap import Basemap
import matplotlib.pyplot as plt
import fiona
from fiona.crs import from_epsg
from geopy.geocoders import Nominatim
import os
import shutil

# For Any given City
city = "Toronto"
# Make a directory for the shapefiles and one for the output
# Make sure that your terminal is running where you want your files!
home_dir = os.getcwd()
wd_output = os.path.join(home_dir, 'cartograpy', city, 'output')
wd_files = os.path.join(home_dir, 'cartograpy', city, 'shapefiles')
if not os.path.exists(wd_output):
    os.makedirs(os.path.join(home_dir, 'cartograpy', city, 'output'))
if not os.path.exists(wd_files):
    os.makedirs(os.path.join(home_dir, 'cartograpy', city, 'shapefiles'))

os.chdir(wd_files)

# Find the bounding box for city
geolocator = Nominatim()
location = geolocator.geocode(city)
south, north, west, east = [float(i) for i in location.raw['boundingbox']]

# Set up the openstreetmap api
api = overpy.Overpass()
# Having the query split here makes it easy to insert whatever tags are desired
q1 = 'way(' + str(south) + ',' + str(west) + ',' + \
    str(north) + ',' + str(east) + ') ['
q2 = '"];(._;>;);out body;'

# Download the data!! This can take a while
# You may add any tags you want here.
# See bottom of script for hints regarding downloading polygons from the OSM api
trunk = api.query(q1 + '"highway"="trunk' + q2)
motorway = api.query(q1 + '"highway"="motorway' + q2)
primary = api.query(q1 + '"highway"="primary' + q2)
secondary = api.query(q1 + '"highway"="secondary' + q2)
tertiary = api.query(q1 + '"highway"="tertiary' + q2)
unclassified = api.query(q1 + '"highway"="unclassified' + q2)
residential = api.query(q1 + '"highway"="residential' + q2)
service = api.query(q1 + '"highway"="service' + q2)

# Write the data to a shapefile
# Again, see bottom of script for other shape types
schema = {'geometry': 'LineString', 'properties': {
    'Name': 'str:80', 'Type': 'str:80'}}
shapeout = city + "_highway.shp"
with fiona.open(shapeout, 'w',
                crs=from_epsg(4326),
                driver='ESRI Shapefile',
                schema=schema) as output:
    for result in [trunk, motorway, primary, secondary]:
        for way in result.ways:
            line = {'type': 'LineString', 'coordinates': [
                (node.lon, node.lat) for node in way.nodes]}
            prop = {'Name': way.tags.get(
                "name", "n/a"), 'Type': way.tags.get("highway", "n/a")}
            output.write({'geometry': line, 'properties': prop})

shapeout = city + "_road.shp"
with fiona.open(shapeout, 'w',
                crs=from_epsg(4326),
                driver='ESRI Shapefile',
                schema=schema) as output:
    for result in [tertiary, unclassified, residential, service]:
        for way in result.ways:
            line = {'type': 'LineString', 'coordinates': [
                (node.lon, node.lat) for node in way.nodes]}
            prop = {'Name': way.tags.get(
                "name", "n/a"), 'Type': way.tags.get("highway", "n/a")}
            output.write({'geometry': line, 'properties': prop})

# For some reason the projection is off right now...
m = Basemap(projection='merc', resolution='f',
            llcrnrlon=west, llcrnrlat=south,
            urcrnrlon=east, urcrnrlat=north)

# Regular ol' B&W Map
plt.figure(figsize=(24, 18))
m.drawmapboundary(fill_color='#EEEEEE', linewidth=0)
m.drawcoastlines(linewidth=0.5, color="#e8e5e5")
m.fillcontinents(color="#FFFFFF")
m.readshapefile(city + "_road", 'roads', linewidth=0.25, color="#0A0A0A")
m.readshapefile(city + "_highway", 'highway', linewidth=0.5, color="#0A0A0A")
plt.savefig(os.path.join(wd_output,  city + '.pdf'),
            bbox_inches='tight', pad_inches=1)

os.chdir(home_dir)
# Be careful: removing the directory that your shapecity files are in
shutil.rmtree(wd_files)


# For information on Polygons, go here: http://wiki.openstreetmap.org/wiki/Area/The_Future_of_Areas

# Making A Polygon:
# schema = {'geometry': 'Polygon', 'properties': {'Name':'str:80', 'Type':'str:80'}}
# shapeout = 'bretagne_forests.shp'
# with fiona.open(shapeout, 'w', crs=from_epsg(4326), driver = 'ESRI Shapefile', schema = schema) as output:
#     for way in forests.ways:
#         poly = {'type': 'Polygon', 'coordinates': [[(node.lon, node.lat) for node in way.nodes]]}
#         prop = {'Name': way.tags.get("name", "n/a"), 'Type': way.tags.get("waterway", "n/a")}
#         output.write({'geometry': poly, 'properties':prop})

# Making A Multipolygon from Relations
# schema = {'geometry': 'MultiPolygon', 'properties': {'Name':'str:80', 'Type':'str:80'}}
# shapeout = 'bretagne_forests.shp'
# with fiona.open(shapeout, 'w', crs=from_epsg(4326), driver = 'ESRI Shapefile', schema = schema) as output:
#     for way in forests.ways:
#         poly = {'type': 'MultiPolygon', 'coordinates': [[(node.lon, node.lat) for node in way.nodes]]}
#         prop = {'Name': way.tags.get("name", "n/a"), 'Type': way.tags.get("waterway", "n/a")}
#         output.write({'geometry': poly, 'properties':prop})
