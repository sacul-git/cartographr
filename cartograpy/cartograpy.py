'''
CARTOGRAPY: A script for making pretty maps in a python2 environment. Created by Robyn and Lucas.

For details on individual tags:
# http: // wiki.openstreetmap.org/wiki/Map_Features
# For details on how to make Polygons(or at least a starting point), see comments at bottom of script. Although honestly, I didnt get very far on that...
'''

import argparse
import overpy
from mpl_toolkits.basemap import Basemap
import matplotlib.pyplot as plt
import fiona
from fiona.crs import from_epsg
from geopy.geocoders import Nominatim
import os
import shutil

road_types = ['trunk', 'motorway', 'primary',
              'secondary', 'tertiary', 'unclassified',
              'residential', 'service']

# create an argument parser and some command line arguments to go with it
parser = argparse.ArgumentParser(description='Plot some cities!')
# argument -c is for the city we want to plot. Defaults to Santa Barbara
parser.add_argument("-c", "--city", type=str,
                    help="What city would you like to plot?",
                    default="Santa Barbara")
# argument -r is for what road types we want to plot
parser.add_argument("-r", "--roads", nargs="+", type=str,
                    help="You can choose to plot: trunk roads, motorways, primary roads, secondary roads, tertiary roads, unclassified roads, residential roads, and/or service roads.",
                    choices=road_types,
                    default=road_types)
parser.add_argument("-e", "--extension", type=str,
                    help="You can choose to save as png or pdf.",
                    choices=['png', 'pdf'],
                    default='png')

args = parser.parse_args()

city = args.city
roads = args.roads
extension = args.extension

# Make a directory for the shapefiles and one for the output
# Make sure that your terminal is running where you want your files!
home_dir = os.getcwd()
wd_output = os.path.join(home_dir, city, 'output')
wd_files = os.path.join(home_dir, city, 'shapefiles')
if not os.path.exists(wd_output):
    os.makedirs(wd_output)
if not os.path.exists(wd_files):
    os.makedirs(wd_files)
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

# Download the data!! This can take a while.
# You may add any tags you want here, just make sure you write them to your shapefile, or they won't actually do anything...
# See bottom of script for hints regarding downloading polygons from the OSM api, but we aren't doing that here, just ways.
print('Collecting the roads. This can take a while for larger areas :)')
dict_of_roads = {r: api.query(
    q1 + '"highway"="{}'.format(r) + q2) for r in roads}

# Write the data to a shapefile
# Again, see bottom of script for other shape types, here we're just saving linestring shapefiles.
schema = {'geometry': 'LineString', 'properties': {
    'Name': 'str:80', 'Type': 'str:80'}}
shapeout = city + "_allroads.shp"
with fiona.open(shapeout, 'w',
                crs=from_epsg(3857),
                driver='ESRI Shapefile',
                schema=schema) as output:
    for road_type, result in dict_of_roads.items():
        for way in result.ways:
            line = {'type': 'LineString', 'coordinates': [
                (node.lon, node.lat) for node in way.nodes]}
            prop = {'Name': way.tags.get(
                "name", "n/a"), 'Type': way.tags.get("highway", "n/a")}
            output.write({'geometry': line, 'properties': prop})

# TODO: Figure out the coastlines. As it is, the coastlines from Basemap are not super detailed. Good enough for lots of things though.
print('Plotting your map. This takes a minute...')
m = Basemap(
    # projection='merc',
    resolution='f',
    llcrnrlon=west, llcrnrlat=south,
    urcrnrlon=east, urcrnrlat=north,
    epsg=3857)

# Regular ol' B&W Map
plt.figure(figsize=(24, 18))
m.drawmapboundary(fill_color='#EEEEEE', linewidth=0)
m.drawcoastlines(linewidth=0.5, color="#e8e5e5")
m.fillcontinents(color="#FFFFFF")
m.readshapefile(city + "_allroads", 'roads', linewidth=0.25, color="#0A0A0A")
# m.readshapefile(city + "_highway", 'highway', linewidth=0.5, color="#0A0A0A")
plt.savefig(os.path.join(wd_output,  city + '.' + extension),
            bbox_inches='tight', pad_inches=1)

os.chdir(home_dir)
# !!! Be careful: removing the directory that your shapecity files are in.
shutil.rmtree(wd_files)
