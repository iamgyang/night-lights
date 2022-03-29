# Clean the objectID dataset
setwd("C:/Users/user/Dropbox/CGD GlobalSat/raw-data/ucdp_war")
load("C:/Users/user/Dropbox/CGD GlobalSat/raw-data/ucdp_war/GED_poly.RData")
df <-
    setDT(wrpol)[, .(OBJECTID, GID_1, GID_0, country, date_start, date_end, best)]
df[, c("date_start", "date_end") := lapply(.SD, as.Date), .SDcols = c("date_start", "date_end")]

# filter for those countries that have matching war!!!!!!!!!!!!there is some mistake here.
df[,iso3c:=name2code(country)]
df <- df[iso3c == GID_0]

df$date <-
    as.Date(df$date_end) - ceiling((as.Date(df$date_end) - as.Date(df$date_start)) / 2)
df[, cnf_dur := date_end - date_start + 1]
df[, year := year(date_start)]
df[, month := month(date_end)]
df <- df[, .(deaths = sum(best, na.rm = T),
             cnf_dur = as.numeric(sum(cnf_dur, na.rm = T))),
         by = .(OBJECTID, GID_1, GID_0, country, year, month)][order(OBJECTID, GID_1, GID_0, country, year, month)]
names(df) <- tolower(names(df))
df$objectid <- df$objectid %>% as.character()
df$gid_1 <- df$gid_1 %>% as.character()
df <- df[!is.na(objectid)]
df %>% readstata13::save.dta13("aggregated_objectID_deaths.dta")

# after 50 deaths:
quantile(na.omit(df$cnf_dur), c(0.25, 0.5, 0.75, 0.9))
quantile(na.omit(df$deaths), c(0.25, 0.5, 0.75, 0.9))
unique(df[cnf_dur >= 30, .(OBJECTID)])

# look at AFTER 2011
# For objectID-months FIRST TIME that experienced more than 50 deaths, do an event study
# for 3 months BEFORE and AFTER
