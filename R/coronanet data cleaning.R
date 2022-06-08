library(data.table)
library(tidyr)
library(dplyr)
library(lubridate)

# load data
cnet <- fread("C:/Users/user/Dropbox/CGD GlobalSat/raw_data/Coronanet/coronanet_release.csv/coronanet_release.csv")

# get variables of interest & filter to subnational data:
cnet <-
cnet %>% 
    as.data.frame() %>% 
    dplyr::select(
        ISO_L2 |
        province |
        country | 
        ISO_A3 |
        contains("index") | 
        contains("date")) %>% 
    filter(!is.na(ISO_L2) & ISO_L2 != "") %>% 
    as.data.frame() %>% 
    # convert back to data table
    as.data.table()

# now, sort based on date and subnational region:
cnet <- cnet[order(ISO_L2, date_announced)]
cnet <- unique(cnet)

# reformate date:
cnet[,date_announced:=lubridate::ymd(date_announced)]

# export:
write.csv(cnet, "coronanet_subnational_lockdown.csv", 
          na = "", row.names = FALSE)