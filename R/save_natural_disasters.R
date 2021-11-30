library(data.table)
library(magrittr)
library(readstata13)
setwd("C:/Users/user/Dropbox/CGD GlobalSat/raw-data/Natural Disasters")
load("nat_disaster_emd_poly.RData")
DT <-
    emdpol %>%
    dplyr::select(
        OBJECTID,
        Disaster.Type,
        starts_with("Start") |
            starts_with("End") |
            starts_with("No")
    ) %>%
    as.data.table()
DT <- DT[!is.na(OBJECTID)]
names(DT) <-
    names(DT) %>% make.names() %>% tolower() %>% gsub(".", "_", ., fixed = T)

# duration variable
DT[, date_start := as.Date(paste0(start_year, "-", start_month, "-", start_day))]
DT[, date_end := as.Date(paste0(end_year, "-", end_month, "-", end_day))]
DT[, dur := date_end - date_start + 1]

DT <- DT[, .(
    no_affected = sum(no_affected, na.rm = T),
    no_injured = sum(no_injured, na.rm = T),
    no_homeless = sum(no_homeless, na.rm = T),
    dur = as.numeric(sum(dur, na.rm = T))
),
by = .(objectid, year = start_year, month = start_month)]

readstata13::save.dta13(as.data.frame(DT), "nat_disaster.dta")