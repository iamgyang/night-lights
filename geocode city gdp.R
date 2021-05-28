
# Packages ---------------------------------------------------

list.of.packages <- c("car", "countrycode", "data.table", "dplyr", "foreign", "ggplot2", "ggrepel", "ggthemes", "graphics", "gvlma", "lubridate", "MASS", "readxl", "Rilostat", "rio", "stargazer", "stats", "tidyr", "utils", "wbstats", "kableExtra", "povcalnetR", "stringr", "MASS","aod", "ggmap")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages)) install.packages(new.packages)
for (package in list.of.packages) {library(eval((package)), character.only = TRUE)}

# defaults ---------------------------------------------------------

# set GGPLOT default theme:
theme_set(theme_clean() +
            theme(plot.background = element_rect(color = "white")))

# default working directory:
user <- Sys.info()["user"]
setwd(paste("C:/Users/", user, "/Dropbox/CGD GlobalSat/", sep = ""))

# city data ----------------------------------------------------

oxf <- list()
oxf <- c(1, 2) %>% lapply(., function(x) {
  read_excel(
    "HF_measures/input/National Accounts/oxford_econ_city_gdppc_data_2013_2016.xlsx",
    sheet = x
  ) %>%
    as.data.table()
})

oxf[[2]] <-
  oxf[[2]][, .(metro, 
             country, 
             delt.gddpc = delt_gdppc_13_14, 
             delt.empl = delt_empl_13_14)]
oxf[[1]] <- 
  oxf[[1]][, .(metro, 
             country,
             delt.gdppc = delt_gdppc_2014_16,
             delt.empl = delt_empl_2014_16)]
oxf[[1]][,yr.st:=2014]
oxf[[1]][,yr.end:=2016]
oxf[[2]][,yr.st:=2013]
oxf[[2]][,yr.end:=2014]

oxf <- rbindlist(oxf, fill = TRUE) %>% as.data.table()

# lat long ------------------------------------------------------

oxf[,name.str:=paste(metro, country)]

register_google(key = "AIzaSyDG_7-cggLHg-umZjSluVp9LdiAVcrg_I8")

unique_loc <- unique(oxf$name.str)
locations_df <- geocode(as.vector(unique_loc))
tomerge <- data.table(cbind(locations_df, name.str = unique_loc))

oxf <- merge(oxf, tomerge, by = c("name.str"), all.x = TRUE)
oxf <- oxf[order(metro, country, yr.st)]


# import parth's file with GIDs and lat longs -----------------------------

citpoly <- fread("HF_measures/input/National Accounts/city_mapped_poly.csv")
cit.bridge <-
  distinct(citpoly[, .(OBJECTID, metro, country, lon, lat, GID_0, GID_1, GID_2)])

write.csv(cit.bridge, "city_ADM_bridge.csv")