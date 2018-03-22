# Hard to count analysis

This repository includes the analysis we ran to get the data for our [hard to count story](https://moose.texastribune.org/hard-to-count/).

The raw data is made available by the [U.S. Census](https://www.census.gov/roam). The Census releases low response scores for each tract in the United States. With this data, we first filtered out Texas. We then download [census tract shapefiles](https://www.census.gov/cgi-bin/geo/shapefiles/index.php) and merged the shapes with the response score data.

We then downloaded [urban area shapefiles](https://www.census.gov/geo/maps-data/data/cbf/cbf_ua.html) and filtered out the top 25 urban areas in Texas. We then ran a query using [ogr2ogr](http://www.gdal.org/ogr2ogr.html) to find all census tracts that intersect with those top 25 urban areas. This allowed us to create the urban area dropdown in the first chart.

The code for these tasks can be found here:

  * process.sh


To help create the prose with the charts, we determined the percentage of Hispanic residents and poor residents who live in census tracts where the low response score is above the national average. We did this for the state of Texas, as well as Houston and Austin.

The code for these tasks can be found here:

  * analysis.r
