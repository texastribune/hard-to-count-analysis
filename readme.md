# Hard to count analysis

This repository includes the code we ran to get the data for our [hard to count story](https://moose.texastribune.org/hard-to-count/).

The raw data is made available by the [U.S. Census](https://www.census.gov/roam), which releases low response scores for each tract in the United States. The scores are based on the likelihood of those living within a census tract will not respond to mailed questionnaires. The national average is [20.7](https://www2.census.gov/geo/pdfs/maps-data/maps/roam/ROAM_User_Guide.pdf). Scores in Texas range from 0 to 45.

With this data, we first filtered out just Texas. We then downloaded [census tract shapefiles](https://www.census.gov/cgi-bin/geo/shapefiles/index.php) and merged the shapefile with the response score data.

We then downloaded [urban area shapefiles](https://www.census.gov/geo/maps-data/data/cbf/cbf_ua.html) and filtered out the 25 most-populous urban areas in Texas. We then ran a query using [ogr2ogr](http://www.gdal.org/ogr2ogr.html) to find all the census tracts that intersect with those 25 urban areas. This allowed us to find the census tracts in those urban areas and create the urban area dropdown in the first chart.

After the merge, we exported the results as a CSV, which was used to make the [D3 charts](https://github.com/d3/d3). This is located in the output folder.

The code for these tasks can be found here:

  * process.sh


To help with the descriptions for these charts, we determined the percentage of Hispanic residents and poor residents who live in census tracts where the low response score is above the national average. We did this for the state of Texas, as well as Houston and Austin. We exported the results as a CSV to the output folder.

The code for these tasks can be found here:

  * analysis.r
