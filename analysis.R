# load packages
library(tidyverse)
library(lubridate)
library(stringr)
library(readxl)
library(lubridate)
library(tidyr)

# Load in our csv
# every row is a Census tract in Texas
input_csv <- read_csv("output/tx_tracts_scores.csv")

createCityTables <- function(){
  # Add a new column called 'above_below'
  # That is used to tract whether tracts are above or below
  # the national average of 20.7
  input_csv$national_avg[
    (input_csv$Low_Response_Score > 20.7) 
    ] <- 'above'
  input_csv$national_avg[
    (input_csv$Low_Response_Score <= 20.7) 
    ] <- 'below'
  
  # Loop through each city we want to create data for
  for (city in c('all', 'Austin, TX', 'Houston, TX')){
    print(city)
    
    # Filter out just the city in the data
    # Unless we want all of Texas
    if (city != 'all') {
      city_input <- input_csv %>% filter(urban_area == city)
    } else {
      city_input <- input_csv
    }
    
    # Sum up Hispanics, poverty
    # So we can get the percentage of each
    sum_all_hispanics <- sum(city_input$Hispanic_ACS_10_14)
    sum_all_pop <- sum(city_input$Tot_Population_ACS_10_14)
    sum_all_poverty <- sum(city_input$Prs_Blw_Pov_Lev_ACS_10_14)
    
    # Group by this new column
    # And add columns so we can determine how many
    # Hispanic and poor residents live in tracts
    # above, below the national average
    nat_avg_population <- city_input %>%
      group_by(national_avg) %>%
      summarize(count = n(),
                sum_pop = sum(Tot_Population_ACS_10_14),
                sum_hispanic = sum(Hispanic_ACS_10_14),
                sum_poverty = sum(Prs_Blw_Pov_Lev_ACS_10_14),
                percent_pop = (sum_pop / sum_all_pop) * 100,
                percent_hispanic = (sum_hispanic / sum_all_hispanics) * 100,
                percent_poverty = (sum_poverty / sum_all_poverty) * 100)
    
    city_lower <- tolower(gsub(", TX", "", city))
    write_csv(nat_avg_population, paste("output/national-avg-population-",
                                        city_lower,
                                        ".csv", sep=""))
  # Close for city loop
  }
# close function
}

createCityTables()


# Find out how many census tracts are in each county
censusTractsCounty <- function() {
  tracts_county <- input_csv %>%
    group_by(County_name) %>%
    summarize(count = n())
  
  write_csv(tracts_county, "output/tx_tracts_per_county.csv")
}
censusTractsCounty()
