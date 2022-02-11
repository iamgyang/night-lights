# Note: I had to do this in R, because otherwise in STATA it would take several 
# days to complete.

rm(list = ls()) # clear the workspace
# Options: ----------------------------------------------------------------

# debugging
options(error=browser)
options(error=NULL)

# disable data.table auto-indexing (causes errors w/ dplyr functions)
options(datatable.auto.index = FALSE)

# Directories -------------------------------------------------------------

# You will have to edit this to be your own computer's working directories:
user <- Sys.info()["user"]
root_dir <- paste0("C:/Users/", user, "/Dropbox/CGD GlobalSat/HF_measures/")
input_dir <- paste0(root_dir, "input")
output_dir <- paste0(root_dir, "output")
code_dir <- paste0(root_dir, "code")
raw_dir <- paste0("C:/Users/", user, "/Dropbox/CGD GlobalSat/raw-data/")
setwd(input_dir)

# Packages ---------------------------------------------------------------
list.of.packages <- c("data.table", "dplyr", "stringdist", "countrycode", "ggplot2", 
                      "ggthemes", "readxl", "tidyr", "glue", "fst", "readstata13")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages)) install.packages(new.packages, dependencies = TRUE)
for (package in list.of.packages) {library(eval((package)), character.only = TRUE)}

# set GGPLOT default theme:
theme_set(theme_clean() + theme(plot.background = element_rect(color = "white")))

# load personal functions
source(paste0("C:/Users/", user, "/Dropbox/Coding_General/personal.functions.R"))


###########################################################################
# THIS IS WHERE THE ACTUAL CODE BEGINS
###########################################################################

# Options -----------------------------------------------------------------

# Read data from the original DTA file?
read_from_dta <- FALSE

# Creates 95th percentile habitable area NTL aggregation ------------------

if (read_from_dta == TRUE ) {
  # load data
  ntl <- as.data.table(readstata13::read.dta13("NTL_VIIRS_appended_cleaned_all.dta"))
  
  # write into FST format:
  setwd(input_dir)
  write_fst(ntl, path = "NTL_VIIRS_appended_cleaned_all.fst", compress = 100)
} else {
  # read from FST format:
  ntl <- as.data.table(read_fst("NTL_VIIRS_appended_cleaned_all.fst"))
}

# load population data (2015 values)
pop_15 <- readstata13::read.dta13(glue("{raw_dir}/WorldPop/world_pop_2015_16.dta"))
pop_15 <- as.data.table(pop_15)
pop_15 <- pop_15[,.(objectid, sum_wpop)]

# merge with population data
ntl <- merge(ntl, pop_15, by = "objectid", all = T)

# create population density figures at ADM2 level
ntl[,pop_density_15:=sum_wpop / sum_area]

# for 79 - 99th percentile::
for (i in seq(79,99,by = 5)){
  
  # define a string for our new variable name
  cutoff <- glue("X{i}_density_cut")
  
  # get the percentile value for each year and country. importantly, we
  # evaluate this percentile cutoff at the country AND year level (as opposed
  # to simply the year level), because there may be some countries that are
  # extremely concentrated (like Argentina or Egypt), while others that are
  # more dispersed. Should we NOT do it at a country-year level, some entire
  # countries theoretically could be omitted by looking only at the areas that
  # have high population density.
  ntl[,c(cutoff):=apply(.SD, 2, function(x) quantile(x, i/100, na.rm = T)), 
      .SDcols = "pop_density_15", by = c("year", "iso3c")]
  ntl <- as.data.table(ntl)
  
  # get the NTL/area at a country year level for those specific locations
  # where the population density exceeds the percentile cutoff
  check_dup_id(ntl, c("iso3c", "objectid", "year","month"))
  
  ntl_at_cutoff <- ntl[pop_density_15 >= eval(as.name(cutoff))]
  ntl_at_cutoff <- ntl_at_cutoff[,
                                 .(
                                   del_sum_pix = sum(del_sum_pix, na.rm = T),
                                   del_sum_area = mean(del_sum_area, na.rm = T),
                                   sum_pix = sum(sum_pix, na.rm = T),
                                   sum_area = mean(sum_area, na.rm = T),
                                   pop_den = mean(pop_density_15, na.rm = T)
                                 ),
                                 by = c("objectid", "iso3c", "year")]
  
  assign(glue("ntl_iso3c_yr_cut_den_{i}"),
         as.data.table(ntl_at_cutoff[,
             .(
               del_sum_pix = sum(del_sum_pix, na.rm = T),
               del_sum_area = sum(del_sum_area, na.rm = T),
               sum_pix = sum(sum_pix, na.rm = T),
               sum_area = sum(sum_area, na.rm = T),
               pop_den = mean(pop_den, na.rm = T)
             )
             , by = c("year", "iso3c")])
         )
  
  # save the file
  readstata13::save.dta13(eval(as.name(glue("ntl_iso3c_yr_cut_den_{i}"))),
                          glue("ntl_iso3c_yr_cut_den_{i}.dta"))
}


