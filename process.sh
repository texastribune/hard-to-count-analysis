# We can use parameters to skip certain tasks within this script
# Example:
# sh process.sh --skip=convert

# Pull out parameters and make them an array
# Called params_array
params=$1
prefix="--skip="
param=${params#$prefix}
IFS=', ' read -r -a params_array <<< ${param}

RAW="pdb2016trv8_us"
EDIT_ONE="a_tx_scores"
EDIT_TWO="b_tx_scores_filter"

VRT="raw.vrt"
RAW_URBAN_SHAPES="cb_2016_us_ua10_500k"
RAW_TRACTS_SHAPES="tl_2016_48_tract"
EDIT_SHAPES_A="a_tx_urban_tracts_all"
EDIT_SHAPES_B="b_tx_urban_tracts_major"
EDIT_SHAPES_C="c_tx_tracts_filter"
EDIT_SHAPES_D="d_tx_urban_tracts"
EDIT_SHAPES_E="e_tx_all_tracts_urban"
EDIT_SHAPES_F="f_tx_all_tracts_urban_scores"
EDIT_SHAPES_G="g_tx_all_tracts_urban_scores_pop"
EDIT_SHAPES_H="h_tx_all_tracts_urban_scores_pop_trim"

OUTPUT="tx_tracts_scores"
OUTPUT_TRIM="tx_tracts_scores_trim"

# Get low scores in Texas
if [[ " ${params_array[*]} " != *" tx-scores "* ]]; then
  cd raw_data/

  csvsql --query "select * from '$RAW' where State_name = 'Texas'" $RAW.csv > ../edits/$EDIT_ONE.csv

  cd ../
fi

# Filter out rows
if [[ " ${params_array[*]} " != *" filter-scores "* ]]; then
  cd edits/

  csvsql --query "select GIDTR, County_name, Tract, Tot_Population_ACS_10_14, Low_Response_Score, Hispanic_ACS_10_14, Hispanic_ACSMOE_10_14, pct_Hispanic_ACS_10_14, pct_Hispanic_ACSMOE_10_14, Prs_Blw_Pov_Lev_ACS_10_14, Prs_Blw_Pov_Lev_ACSMOE_10_14, pct_Prs_Blw_Pov_Lev_ACS_10_14, pct_Prs_Blw_Pov_Lev_ACSMOE_10_14 from '$EDIT_ONE' where State_name = 'Texas'" $EDIT_ONE.csv > $EDIT_TWO.csv

  cd ../
fi

# Get all urban areas in Texas
if [[ " ${params_array[*]} " != *" geo-urban-all "* ]]; then
  cd raw_data/

  ogr2ogr -dialect sqlite3 -sql "SELECT * FROM $RAW_URBAN_SHAPES WHERE NAME10 LIKE '%, TX%'" $EDIT_SHAPES_A.shp ../$VRT -progress

  cp $EDIT_SHAPES_A* ../edits/
  rm $EDIT_SHAPES_A*
  cd ../
fi

# Get the largest urban areas in Texas
if [[ " ${params_array[*]} " != *" geo-urban-major "* ]]; then
  cd edits/

  ogr2ogr -dialect sqlite3 -sql "SELECT GEOID10, NAME10 as urban_area FROM $EDIT_SHAPES_A WHERE NAME10 = 'Dallas--Fort Worth--Arlington, TX' OR NAME10 = 'Houston, TX' OR NAME10 = 'San Antonio, TX' OR NAME10 = 'Austin, TX' OR NAME10 = 'McAllen, TX' OR NAME10 = 'El Paso, TX--NM' OR NAME10 = 'Corpus Christi, TX' OR NAME10 = 'Brownsville, TX' OR NAME10 = 'Killeen, TX' OR NAME10 = 'Beaumont, TX' OR NAME10 = 'Lubbock, TX' OR NAME10 = 'Laredo, TX' OR NAME10 = 'Amarillo, TX' OR NAME10 = 'Waco, TX' OR NAME10 = 'College Station--Bryan, TX' OR NAME10 = 'Tyler, TX' OR NAME10 = 'Longview, TX' OR NAME10 = 'Abilene, TX' OR NAME10 = 'Wichita Falls, TX' OR NAME10 = 'Texarkana--Texarkana, TX--AR' OR NAME10 = 'Odessa, TX' OR NAME10 = 'Midland, TX' OR NAME10 = 'Sherman, TX' OR NAME10 = 'Victoria, TX' OR NAME10 = 'San Angelo, TX'" $EDIT_SHAPES_B.shp ../$VRT -progress

  cd ../
fi


# Get tracts in urban areas
if [[ " ${params_array[*]} " != *" geo-filter-tracts "* ]]; then
  cd raw_data/
  cp $RAW_TRACTS_SHAPES* ../edits/
  cd ../edits/

  ogr2ogr -dialect sqlite3 -sql "SELECT GEOID FROM $RAW_TRACTS_SHAPES" $EDIT_SHAPES_C.shp ../$VRT -progress

  cp $RAW_TRACTS_SHAPES* ../raw_data/
  rm $RAW_TRACTS_SHAPES*
  cd ../
fi

# Get tracts in urban areas
if [[ " ${params_array[*]} " != *" geo-urban-tracts "* ]]; then
  cd edits/

  ogr2ogr -dialect sqlite -sql "SELECT * FROM $EDIT_SHAPES_C a, $EDIT_SHAPES_B b WHERE ST_Intersects(a.geometry, b.geometry)" $EDIT_SHAPES_D.shp ../$VRT -progress
  cd ../
fi

# Merge all tracts with low scores data
if [[ " ${params_array[*]} " != *" geo-all-join-urban "* ]]; then
  cd edits/

  ogr2ogr -sql "SELECT * FROM $EDIT_SHAPES_C LEFT JOIN $EDIT_SHAPES_D ON $EDIT_SHAPES_C.GEOID = $EDIT_SHAPES_D.GEOID" $EDIT_SHAPES_E.shp ../$VRT -progress

  cd ../
fi

# Merge all tracts with low scores data
if [[ " ${params_array[*]} " != *" geo-all-join-scores "* ]]; then
  cd edits/

  ogr2ogr -sql "SELECT * FROM $EDIT_SHAPES_E LEFT JOIN '$EDIT_TWO.csv'.$EDIT_TWO ON $EDIT_SHAPES_E.GEOID = $EDIT_TWO.GIDTR" $EDIT_SHAPES_F.shp ../$VRT -progress

  cd ../
fi

# Filter where population is more than a certain amount
if [[ " ${params_array[*]} " != *" geo-all-pop "* ]]; then
  cd edits/

  ogr2ogr -sql "SELECT urban_area, County_nam, Tract, Tot_Popula, Low_Respon, Hispanic_A, Hispanic_1, cast(pct_Hispan AS numeric(10,1)) as pct_Hispan, cast(pct_Hisp_1 AS numeric(10,1)) as pct_Hisp_1, Prs_Blw_Po, Prs_Blw__1, cast(pct_Prs_Bl AS numeric(10,1)) as pct_Prs_Bl, cast(pct_Prs__1 AS numeric(10,1)) as pct_Prs__1 FROM $EDIT_SHAPES_F WHERE Low_Respon >= '0'" $EDIT_SHAPES_G.shp ../$VRT -progress

  ogr2ogr -sql "SELECT urban_area, County_nam, Tract, Low_Respon, cast(pct_Hispan AS numeric(10,1)) as pct_Hispan, cast(pct_Hisp_1 AS numeric(10,1)) as pct_Hisp_1, cast(pct_Prs_Bl AS numeric(10,1)) as pct_Prs_Bl, cast(pct_Prs__1 AS numeric(10,1)) as pct_Prs__1 FROM $EDIT_SHAPES_F WHERE Low_Respon >= '0' ORDER BY urban_area ASC" $EDIT_SHAPES_H.shp ../$VRT -progress

  # ogr2ogr -dialect sqlite -sql "SELECT urban_area, County_nam, Tract, Tot_Popula, Low_Respon, Hispanic_A, Hispanic_1, pct_Hispan, pct_Hisp_1, Prs_Blw_Po, Prs_Blw__1, pct_Prs_Bl, pct_Prs__1 FROM $EDIT_SHAPES_F WHERE Low_Respon >= '0'" $EDIT_SHAPES_G.shp ../$VRT -progress
  cd ../
fi

# Merge city tracts with low scores data
if [[ " ${params_array[*]} " != *" geo-export "* ]]; then
  cd edits/

  # Rename columns
  ogr2ogr -f CSV $OUTPUT.csv $EDIT_SHAPES_G.shp
  sed -i '1s/County_nam/County_name/' $OUTPUT.csv
  sed -i '1s/Tot_Popula/Tot_Population_ACS_10_14/' $OUTPUT.csv
  sed -i '1s/Low_Respon/Low_Response_Score/' $OUTPUT.csv
  sed -i '1s/Hispanic_A/Hispanic_ACS_10_14/' $OUTPUT.csv
  sed -i '1s/Hispanic_1/Hispanic_ACSMOE_10_14/' $OUTPUT.csv
  sed -i '1s/pct_Hispan/pct_Hispanic_ACS_10_14/' $OUTPUT.csv
  sed -i '1s/pct_Hisp_1/pct_Hispanic_ACSMOE_10_14/' $OUTPUT.csv
  sed -i '1s/Prs_Blw_Po/Prs_Blw_Pov_Lev_ACS_10_14/' $OUTPUT.csv
  sed -i '1s/Prs_Blw__1/Prs_Blw_Pov_Lev_ACSMOE_10_14/' $OUTPUT.csv
  sed -i '1s/pct_Prs_Bl/pct_Prs_Blw_Pov_Lev_ACS_10_14/' $OUTPUT.csv
  sed -i '1s/pct_Prs__1/pct_Prs_Blw_Pov_Lev_ACSMOE_10_14/' $OUTPUT.csv

  cp $OUTPUT.csv ../output/
  cp $OUTPUT.csv ../../hard-to-count/app/assets/data/
  rm $OUTPUT.csv

  # Rename columns
  ogr2ogr -f CSV $OUTPUT_TRIM.csv $EDIT_SHAPES_H.shp
  sed -i '1s/County_nam/County_name/' $OUTPUT_TRIM.csv
  sed -i '1s/Low_Respon/Low_Response_Score/' $OUTPUT_TRIM.csv
  sed -i '1s/pct_Hispan/pct_Hispanic_ACS_10_14/' $OUTPUT_TRIM.csv
  sed -i '1s/pct_Hisp_1/pct_Hispanic_ACSMOE_10_14/' $OUTPUT_TRIM.csv
  sed -i '1s/pct_Prs_Bl/pct_Prs_Blw_Pov_Lev_ACS_10_14/' $OUTPUT_TRIM.csv
  sed -i '1s/pct_Prs__1/pct_Prs_Blw_Pov_Lev_ACSMOE_10_14/' $OUTPUT_TRIM.csv

  cp $OUTPUT_TRIM.csv ../output/
  cp $OUTPUT_TRIM.csv ../../hard-to-count/app/assets/data/
  rm $OUTPUT_TRIM.csv


  cd ../
fi
