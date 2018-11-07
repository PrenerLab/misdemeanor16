Create Data Set
================
Christopher Prener, Ph.D.
(November 07, 2018)

## Introduction

This notebook creates the crime data set for further analysis.

## Dependencies

This notebook depends on the following packages:

``` r
# primary data tools
library(compstatr)     # work with stlmpd crime data

# tidyverse packages
library(dplyr)         # data wrangling
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` r
library(readr)         # working with csv data

# spatial packages
library(sf)            # working with spatial data
```

    ## Linking to GEOS 3.6.1, GDAL 2.1.3, proj.4 4.9.3

``` r
library(tigris)        # tiger/line api access
```

    ## To enable 
    ## caching of data, set `options(tigris_use_cache = TRUE)` in your R script or .Rprofile.

    ## 
    ## Attaching package: 'tigris'

    ## The following object is masked from 'package:graphics':
    ## 
    ##     plot

``` r
# other packages
library(janitor)       # frequency tables
library(here)          # file path management
```

    ## here() starts at /Users/chris/GitHub/Lab/misdemeanor16

``` r
library(knitr)         # output
library(testthat)      # unit testing
```

    ## 
    ## Attaching package: 'testthat'

    ## The following object is masked from 'package:dplyr':
    ## 
    ##     matches

## Create Data

Data downloaded from the STLMPD website come in `.csv` format but with
the wrong file extension. The following bash script copies them to a new
subdirectory and fixes the file extension issue:

``` bash
# change working directory
cd ..

# execute cleaning script
bash source/reformatHTML.sh
```

    ## mkdir: data/raw/csv/2016: File exists
    ## mkdir: data/raw/csv/2017: File exists
    ## mkdir: data/raw/csv/2018: File exists

## Load Data

With our data renamed, we build a year list objects for 2016, 2017, and
2018 crimes:

``` r
data2016 <- cs_load_year(here("data", "raw", "csv", "2016"))
data2017 <- cs_load_year(here("data", "raw", "csv", "2017"))
data2018 <- cs_load_year(here("data", "raw", "csv", "2018"))
```

    ## Warning in cs_load_year(here("data", "raw", "csv", "2018")): There are
    ## fewer than 12 files in the specified folder. You are only loading a partial
    ## year.

We can visually verify that the 2018 folder is the one causing the
warning here, and that we have the maximum number of files we can work
from.

## Validate Data

Next we make sure there are no problems with the crime files in terms of
incongruent columns:

``` r
cs_validate_year(data2016, year = "2016")
```

    ## [1] TRUE

All of the data passes the validation checks.

``` r
cs_validate_year(data2017, year = "2017")
```

    ## [1] FALSE

We can use the `verbose = TRUE` option on `cs_validate_year()` to
identify areas where the validation checks have failed:

``` r
cs_validate_year(data2017, year = "2017", verbose = TRUE)
```

    ## # A tibble: 12 x 9
    ##    namedMonth codedMonth valMonth codedYear valYear oneMonth varCount
    ##    <chr>      <chr>      <lgl>        <int> <lgl>   <lgl>    <lgl>   
    ##  1 January    January    TRUE          2017 TRUE    TRUE     TRUE    
    ##  2 February   February   TRUE          2017 TRUE    TRUE     TRUE    
    ##  3 March      March      TRUE          2017 TRUE    TRUE     TRUE    
    ##  4 April      April      TRUE          2017 TRUE    TRUE     TRUE    
    ##  5 May        May        TRUE          2017 TRUE    TRUE     FALSE   
    ##  6 June       June       TRUE          2017 TRUE    TRUE     TRUE    
    ##  7 July       July       TRUE          2017 TRUE    TRUE     TRUE    
    ##  8 August     August     TRUE          2017 TRUE    TRUE     TRUE    
    ##  9 September  September  TRUE          2017 TRUE    TRUE     TRUE    
    ## 10 October    October    TRUE          2017 TRUE    TRUE     TRUE    
    ## 11 November   November   TRUE          2017 TRUE    TRUE     TRUE    
    ## 12 December   December   TRUE          2017 TRUE    TRUE     TRUE    
    ## # ... with 2 more variables: valVars <lgl>, valClasses <lgl>

The data for May 2017 do not pass the validation checks. We can extract
this month and confirm that there are too many columns in the May 2017
release. Once we have that confirmed, we can standardize that month and
re-run our validation.

``` r
# extract data
may2017 <- cs_extract_month(data2017, month = "May")

# unit test column number
expect_equal(ncol(may2017), 26)

# remove object
rm(may2017)

# standardize months
data2017 <- cs_standardize(data2017, month = "May", config = 26)

# validate data
cs_validate_year(data2017, year = "2017")
```

    ## [1] TRUE

We now get a `TRUE` value for `cs_validate_year()` and can move on to
2018 data.

``` r
cs_validate_year(data2018, year = "2018")
```

    ## [1] TRUE

## Collapse Data

With the data validated, we collapse each year into a single, flat
object:

``` r
data2016_flat <- cs_collapse(data2016)
data2017_flat <- cs_collapse(data2017)
data2018_flat <- cs_collapse(data2018)
```

What we need for this project is a single object with only the crimes
for 2016. Since crimes were *reported* in both the 2017 and 2018
flattened for 2016, we need to merge all three tables and then retain
only the 2016 crimes. The `cs_combine()` function will do this, and
return only the known crimes for
2016:

``` r
crimes2016 <- cs_combine(type = "year", date = 2016, data2016_flat, data2017_flat, data2018_flat)
```

### Clean-up Enviornment

With our data created, we can remove some of the intermediary objects
we’ve
created:

``` r
rm(data2016, data2016_flat, data2017, data2017_flat, data2018, data2018_flat)
```

## Remove Unfounded Crimes and Subset Based on Type of Crime:

The following code chunk removes unfounded crimes (those where `Count ==
-1`) and then creates a data frame for all part one crimes:

``` r
crimes2016 %>% 
  cs_filter_count(var = Count) %>%
  cs_missing_xy(varx = XCoord, vary = YCoord, newVar = xyStatus) -> misCrimes

misCrimes %>%
  tabyl(xyStatus) %>%
  adorn_pct_formatting(digits = 3) %>%
  kable()
```

| xyStatus |     n | percent |
| :------- | ----: | :------ |
| FALSE    | 48389 | 97.498% |
| TRUE     |  1242 | 2.502%  |

We’re going to drop 2.5% of the data because it is missing spatial
references. This is a limitation of this data set. We’ll also subset
based on crime type to retain only the following:

1.  13) Stolen Property: Buying, Receiving, Possessing

2.  14) Vandalism

3.  15) Weapons: Carrying, Possessing, etc.

4.  18) Drug Abuse Violations

5.  25) Vagrancy

6.  27) Suspicion

<!-- end list -->

``` r
misCrimes %>%
  filter(xyStatus == FALSE) %>%
  cs_crime_cat(var = Crime, newVar = crimeCat, output = "numeric") %>%
  filter(crimeCat == 13 | crimeCat == 14 | crimeCat == 15 | 
           crimeCat == 18 | crimeCat == 25 | crimeCat == 27) -> misCrimes

# logic check
expect_equal(nrow(misCrimes), 8350)
```

Finally, we’ll write the full crimes data set to the `data/clean`
subdirectory:

``` r
write_csv(misCrimes, path = here("data", "clean", "misdemeanors2016.csv"))
```

This is now available for any individual-level analyses.

## Project Data

We project the main set of previously geocoded data, remove excess
columns, and transform the data to NAD
1983:

``` r
misCrimes_sf <- st_as_sf(misCrimes, coords = c("XCoord", "YCoord"), crs = 102696)

misCrimes_sf %>%
  select(-xyStatus) %>%
  st_transform(crs = 4269) -> misCrimes_sf
```

## Spatial Join

First, we download geometric data describing St. Louis census tract
boudaries, and clean it so that only the `GEOID` variable and the
`geometry` column remain:

``` r
stl <- tracts(state = 29, county = 510, class = "sf")
```

``` r
stl %>% 
  st_transform(crs = 4269) %>%
  select(GEOID) -> stl
```

Then we’ll complete a spaital join to append the `GEOID` of the
encompassing census tract to each crime that falls within it, and sum
the total number of crimes per census
    tract:

``` r
tracts <- st_intersection(misCrimes_sf, stl)
```

    ## although coordinates are longitude/latitude, st_intersection assumes that they are planar

    ## Warning: attribute variables are assumed to be spatially constant
    ## throughout all geometries

``` r
st_geometry(tracts) <- NULL

tracts %>%
  group_by(GEOID) %>%
  summarise(crimes = n()) -> tracts

# logic check
expect_equal(sum(tracts$crimes), 8326)
```

A total of 24 crimes are not included in `tracts` because their spatial
data located them outside of the City of St. Louis boundary.

Finally, we’ll write this to `data/clean` for later use:

``` r
write_csv(tracts, path = here("data", "clean", "tractCounts.csv"))
```
