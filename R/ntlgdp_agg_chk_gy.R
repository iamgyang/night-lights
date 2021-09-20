library(sp)
library(maptools)
library(data.table)
library(plotly)
library(ggplot2)
library(readstata13)
library(readxl)
library(zoo)
library(scales)
library(RColorBrewer)
library(ggthemes)
library(rgdal)
library(fixest)
library(dplyr)
options(scipen = 99)
source("http://peterhaschke.com/Code/multiplot.R")

# Compare aggregation ---------------------------------------------

# country year regression data (Negatives removed at admin2 level) -----------
neg_rem <- fread('C:/Users/gyang/Dropbox/CGD GlobalSat/HF_measures/input/merged_month_gid_2.csv')

# subset for years presents
reg_dt <- neg_rem[!is.na(neg_rem$sum_pix),]
# reg_dt <- reg_dt %>% filter(iso3c == "SGP" & year == 2019) %>% dfdt

r3 <-
  feols(
    log_Oxford ~ log_sum_pix |
      iso3c + year_f,
    model = 'within',
    data = reg_dt
  )
r4 <-
  feols(log(Oxford) ~ log(sum_pix) |
          iso3c + year_f,
        model = 'within',
        data = reg_dt)
summary(r4) # Matched
length(unique(reg_dt$iso3c))  # 187
length(unique(reg_dt$year))   # 9

# admin2 monthly: raw data -------------------------------------------------
# load admin2 data


fst.reading <- FALSE

if (fst.reading) {
  bruce <- read.fst("bruce.fst")
} else {
  bruce <- readstata13::read.dta13("NTL_GDP_month_ADM2.dta")
  write.fst(bruce, "bruce.fst", compress = 100)
}

dfdt <- function(x) x %>% as.data.frame() %>% as.data.table()

nlgdad <- bruce %>% dfdt
length(unique(nlgdad$gid_2)) # 46074
table(is.na(nlgdad$gid_2))   # 4842495

# make negatives as 0
nlgdad[,sum_pix_clb:=ifelse(sum_pix < 0, 0, sum_pix)]
nlgdad[,pol_area_clb:=ifelse(pol_area < 0, 0, pol_area)]

# first, take a mean across ADM2 by area:
nlgdad <- nlgdad[, .(
  sum_pix = sum(sum_pix, na.rm = T),
  pol_area = sum(pol_area, na.rm = T),
  sum_pix_clb = sum(sum_pix_clb, na.rm = T),
  pol_area_clb = sum(pol_area_clb, na.rm=T),
  # SHOULD BE A MEAN
  WDI = mean(WDI, na.rm = T),
  # SHOULD BE A MEAN
  ox_rgdp_lcu = mean(ox_rgdp_lcu, na.rm = T)
),
by = .(iso3c, month, year)]

# then get a sum across year:
ctyr <-
  nlgdad[, .(
    sum_pix = sum(sum_pix, na.rm = T),
    pol_area = sum(pol_area, na.rm = T),
    sum_pix_clb = sum(sum_pix_clb, na.rm = T),
    pol_area_clb = sum(pol_area_clb, na.rm = T),
    # SHOULD BE A MEAN--WDI IS ANNUAL
    WDI = mean(WDI, na.rm = T),
    ox_rgdp_lcu = sum(ox_rgdp_lcu, na.rm = T)
  ),
  by = .(iso3c, year)]

# checks
length(unique(ctyr$iso3c))  # 187
length(unique(ctyr$year))   # 9
ctyr$year_f <- as.factor(ctyr$year)
ctyr$iso3c_f <- as.factor(ctyr$iso3c)
ctyr$sum_pix_clb_area <- ctyr$sum_pix_clb / ctyr$pol_area_clb

# check reg
r5 <-
  feols(
    log(ox_rgdp_lcu) ~ log(sum_pix_clb_area) |
      iso3c_f + year_f,
    model = 'within',
    data = ctyr
  )
summary(r5) # Matched
etable(r4, r5)

# finding where the difference is
table(is.na(ctyr$ox_rgdp_lcu))
table(is.na(reg_dt$Oxford))

# just merge oxford gdp for both
mtest <- 
  merge(x = ctyr[, c(
    "iso3c",
    "year",
    "ox_rgdp_lcu",
    "sum_pix_clb_area"
  )],
  y = reg_dt[, c("iso3c", "year", "Oxford", 'sum_pix')],
  by = c("iso3c", "year"))

mtest[, diff := abs(Oxford - ox_rgdp_lcu)]
View(mtest[diff>20])

plot <- ggplot(mtest[diff > 20],
               aes(x = log(ox_rgdp_lcu),
                   y = log(Oxford))) +
  geom_point() + 
  geom_abline(
    slope = 1,
    intercept = 0,
    size = 0.5,
    color = "red"
  )

ggsave("comparing NTL aggregation.png", plot)







bruce <- read.fst("bruce.fst") %>% dfdt
bruce[sum_pix < 0, sum_pix := 0]
bruce[sum_pix < 0, pol_area := 0]
bruce <- bruce[, .(
  ox = mean(ox_rgdp_lcu, na.rm = T),
  pol_area = sum(pol_area),
  sum_pix = sum(sum_pix)
),
by = .(year, month, iso3c)]
