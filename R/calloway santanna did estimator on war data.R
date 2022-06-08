# -------------------------------------------------------------------------

# import
setwd("C:/Users/gyang/Dropbox/CGD GlobalSat/HF_measures/input")
pvq <-
  as.data.table(readstata13::read.dta13("war_nat_disaster_event_prior_to_cutoff.dta"))

# delete all of >=2019
pvq <- pvq[year<=2018 & year>=2013]

# -------------------------------------------------------------------------

# I find it hard to believe that any of the DiD assumptions are satisfied here.
# 1. no anticipation is violated (can we really say wars are unexpected?)
# 2. we don't have units that retain treatment (units almost always stop having
#    war)
# 3. most importantly, heterogeneity presumably exists independent of units'
#    time after treatment (e.g. GFC means that all units had similar GDP drop in
#    2008 time, which gets lost if you center the treatment time variable prior
#    to running dynamic TWFE)

# I suggest we just run regression of GDP on deaths: log(GDP) ~ log(deaths) +
# ADM2 FE + date (year+mo) FE --> yields negative highly significant
# coefficient, but only for BM

feols(ln_sum_pix_bm_area~log(deaths)|as.factor(objectid) + as.factor(year) +
  as.factor(month), data = pvq)
feols(ln_sum_pix_area~log(deaths)|as.factor(objectid) + as.factor(year) +
  as.factor(month), data = pvq)

# -------------------------------------------------------------------------

# create date variable
pvq[, time_date := paste0(month, "-", year)]
pvq[, time_date := lubridate::my(time_date)]

save.image("temp_war.RData")
load("temp_war.RData")

# time_date should be the number of months since 1/1/1970
pvq[, time_date := round(as.numeric(time_date) / 30.4167, 0)]

# treatment time_date
pvq[tr == 1, tr_time_date := round(as.numeric(min(time_date, na.rm = T))), by = "objectid"]
pvq[tr_at_all == 0, tr_time_date := 0]

# ignore cases where we are no longer at war, but we are AFTER the start of the
# first war. 
nrow(pvq)
# pvq <- pvq[ !(tr == 0 & time_date > tr_time_date & tr_time_date != 0)]

# this yields 4669125 objectID-months
nrow(pvq)

# convert objectID to numeric
pvq[,objectid_num:=as.numeric(as.factor(objectid))]

# restrict to variables of interest:
pvq <- 
  pvq[,.(objectid_num, ln_sum_pix_bm_area, time_date, tr_time_date)]
pvq <- as.data.frame(pvq)
check_dup_id(pvq, c("objectid_num", "time_date"))

# balanced panel:
surface <- CJ(objectid_num = unique(pvq$objectid_num), 
   time_date = unique(pvq$time_date))
pvq <- merge(surface, pvq, by = c('objectid_num','time_date'),all=T)


# Problem here is that we can no longer use the Calloway Santanna estimator
# because the units drop out of treatment after certain time. And since we are
# comparing *non-centered* periods (as is the case with the Calloway Santanna
# estimator), areas that are not treated end up affecting the estimates for
# those that are.

# run DID:
example_attgt <- att_gt(
  yname = "ln_sum_pix_bm_area",
  tname = "time_date",
  idname = "objectid_num",
  gname = "tr_time_date",
  # xformla = ~ X,
  data = pvq
)




