# cartographr / cartograpy

Some scripts to generate nice maps using OSM data in Python and R

![Bretagne][Bretagne]

[Bretagne]: https://github.com/sacul-git/cartographr/blob/master/cartograpy/example/Bretagne/output/bretagne.png "Bretagne"


## cartograpy

Cartograpy is the python version of these scripts. It's set up to be run from the command line.

But first, it's important to note that cartograpy relies on some pretty finicky modules, and hasn't been tested on multiple versions. It works fine on:

- `overpy` version `1.1`
- `matplotlib` version `2.1.1`
- `fiona` version `1.7.10`
- `geopy` version `1.11.0`

### cartograpy usage

- Clone or download this repository from github
- Navigate to the cartograpy foler in the directory your just downloaded in the command line (Windows) or terminal (Mac and Linux)
- In the command line, run `python cartograpy.py`

This will create a map of Santa Barbara's roads (the default):

![Santa Barbara][Santa Barbara]

[Santa Barbara]: https://github.com/sacul-git/cartographr/blob/master/cartograpy/example/Santa%20Barbara_full.png "Santa Barbara"

But wait! Maybe you don't want a map of Santa Barbara! Maybe you prefer another city? You can use the `-c` or `--city` argument to specify which city you want plotted. Let's try with Denver, Colorado:

    python cartograpy.py -c "Denver CO"

It takes a while to download these roads, as it's a pretty big city. The output looks like:

![Denver, CO][Denver, CO]

[Denver, CO]: https://github.com/sacul-git/cartographr/blob/master/cartograpy/example/Denver%20CO_full.png "Denver, CO"
 
That's a lot of roads! No wonder it took so long to download... You can use the `-r` or `--roads` argument to specify which road types you want. You can pick from 'trunk', 'motorway', 'primary', 'secondary', 'tertiary', 'unclassified','residential', and or 'service' roads.

Let's try with just trunk, primary, and residential roads:

    python cartograpy.py -c "Denver CO" -r motorway trunk primary residential

This is much faster. You end up with:


![Denver, CO 2][Denver, CO 2]

[Denver, CO 2]: https://github.com/sacul-git/cartographr/blob/master/cartograpy/example/Denver%20CO_trunk_primary_residential.png "Denver, CO 2"

You could also specify whether you want a png or pdf output with the `-e` or `--extension` argument. This would get you the same map but as a pdf:


    python cartograpy.py -c "Denver CO" -r motorway trunk primary residential -e pdf


