library('sp'); library('maptools');library('data.table');library(plotly)
library(ggplot2); library(readstata13); library(readxl); library(zoo); library(scales)
library(RColorBrewer); library(ggthemes); library(rgdal);library(fixest)
options(scipen=99)
source("http://peterhaschke.com/Code/multiplot.R")

# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------
#             ------------------- Compare aggregation ------------------ 
# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------



# Check aggregation processs
# ========================================================================================
# country year regression data (Negatives removed at admin2 level)
# --------------------------------
neg_rem <- read.csv('/Users/gyang/Desktop/CGD/Projects/Globalsat/data/HWS & country level/merged_month_gid_2_17jun HWS reg replication.csv')
# subset for years presents
reg_dt <- neg_rem[!is.na(neg_rem$sum_pix),]
r3 <- feols(log_delt_Oxford_1 ~ log_delt_sum_pix_1|iso3c +year_f, model='within',data=reg_dt)
r4 <- feols(log(Oxford) ~ log(sum_pix)|iso3c +year_f, model='within',data=reg_dt)
summary(r4) # Matched
length(unique(reg_dt$iso3c))  # 187
length(unique(reg_dt$year))   # 9



# admin2 monthly: raw data
# --------------------------------
# load admin2 data
load('/Users/gyang/Desktop/CGD/Projects/Globalsat/data/extracted viirs/compiled global ntl/NTL_GDP_month_ADM2_17Jun21.RData')
dim(nlgdad2)
nlgdad2 <- data.table(nlgdad2)
length(unique(nlgdad2$gid_2)) # 46074
table(is.na(nlgdad2$gid_2))   # 4842495
length(unique(nlgdad2$iso3c)) # 187
table(is.na(nlgdad2$iso3c))   # 4842495
table(nlgdad2$sum_pix<0)   # 4842495

# make negatives as 0
nlgdad2$sum_pix_clb <- ifelse(nlgdad2$sum_pix<0,0,nlgdad2$sum_pix)

# aggreagte this to country year level
ctyr <- nlgdad2[,.(sum_pix = sum(sum_pix, na.rm=T), pol_area = sum(pol_area, na.rm=T),
                sum_pix_clb = sum(sum_pix_clb, na.rm=T), 
                imf_rgdp_lcu = sum(imf_rgdp_lcu, na.rm=T), pwt_rgdpna = sum(pwt_rgdpna, na.rm=T),
                WDI = sum(WDI, na.rm=T), ox_rgdp_lcu = sum(ox_rgdp_lcu, na.rm=T),
                imf_quart_nom_gdp = sum(imf_quart_nom_gdp, na.rm=T), 
                imf_quart_rgdp = sum(imf_quart_rgdp, na.rm=T)),
             by = .(iso3c,year)]

# checks
length(unique(ctyr$iso3c))  # 187
length(unique(ctyr$year))   # 9
ctyr$year_f <- as.factor(ctyr$year)
ctyr$iso3c_f <- as.factor(ctyr$iso3c)
ctyr$sum_pix_clb_area <- ctyr$sum_pix_clb/ctyr$pol_area

# check reg
r5 <- feols(log(ox_rgdp_lcu) ~ log(sum_pix_clb_area)|iso3c_f +year_f, model='within',data=ctyr)
summary(r5) # Matched
etable(r4, r5)

# main regression takes 163 countries
# agg takes 144 countries
 
# finding where the difference is
table(is.na(ctyr$ox_rgdp_lcu))
table(ctyr$ox_rgdp_lcu ==0)  # 387
table(is.na(reg_dt$Oxford))  # 216
table(reg_dt$Oxford ==0)

class(reg_dt$Oxford)

# ========================================================================================


# 1 July George updated data
# ========================================================================================
# george corrected data 
admn_jul <- read.dta13('NTL_GDP_month_ADM2.dta')
dim(admn_jul)

# level of the data
lvl_adm <- paste0(admn_jul$iso3c, admn_jul$gid_1, admn_jul$gid_2)
length(unique(lvl_adm)) # 46074
# 4837770/46074 = 105 number of months

lvl_overall <- paste0(admn_jul$objectid, 
                      admn_jul$iso3c, admn_jul$name_0, admn_jul$gid_1,admn_jul$name_1, 
                      admn_jul$gid_2,admn_jul$time, admn_jul$date2, 
                      admn_jul$yq, admn_jul$year, admn_jul$month, admn_jul$quarter)
length(unique(lvl_overall)) # 4837770
length(lvl_overall) # 4842495
nrow(admn_jul) - length(unique(lvl_overall)) # 4725 repeated ?
# # 4725 repeated NO: as this the number of objectids
# that means one country exists without 
length(lvl_overall) - length(unique(lvl_overall))  # 4725 also the name
# find duplicates here through the ids
table(duplicated(lvl_overall))
duprows <- unique(lvl_overall[duplicated(lvl_overall)])
length(duprows)
# 4725/105 = 45

# quick checks
length(unique(admn_jul$objectid)) # 46074

length(unique(admn_jul$gid_2)) # 46074
table(admn_jul$gid_2=="") # FALSE ALL
table(is.na(admn_jul$gid_2))   # 4842495

length(unique(admn_jul$iso3c)) # 187
table(is.na(admn_jul$iso3c))   # 4842495
table(admn_jul$gadmid=="") # 46074
# FALSE    TRUE 
# 18375 4824120 
table(admn_jul$iso=="") # 46074
# FALSE    TRUE 
# 18375 4824120 

# checks missing % on GDP data
table(is.na(admn_jul$imf_quart_rgdp))/nrow(admn_jul)
# FALSE      TRUE 
# 0.5691611 0.4308389 
# --  2 july
# FALSE      TRUE 
# 0.6301487 0.3698513 


# NOT USING
table(is.na(admn_jul$imf_quart_nom_gdp))/nrow(admn_jul)
# FALSE      TRUE 
# 0.6346365 0.3653635 
table(is.na(admn_jul$pwt_rgdpna))/nrow(admn_jul)
# FALSE      TRUE 
# 0.8548135 0.1451865 
# USING
table(is.na(admn_jul$ox_rgdp_lcu))/nrow(admn_jul)
# FALSE      TRUE 
# 0.8841258 0.1158742 
table(is.na(admn_jul$WDI))/nrow(admn_jul)
# FALSE       TRUE 
# 0.97566977 0.02433023 
table(is.na(admn_jul$imf_rgdp_lcu))/nrow(admn_jul)
# FALSE      TRUE 
# 0.9803087 0.0196913 

# ------------------- CALL -----
# CALL ------------
# 1.) using PWT, WDI, Oxford, IMF-LCU (imf_rgdp_lcu) and leaving out imf_quart_rgdp, imf_quart_nom_gdp for now
# 2.) this is based on % missing rows (training) the former 4 PWT, WDI, Oxford, IMF-LCU have between 2-14% missing data at admin2 month level
# 3.) within these 4 Oxford,IMF, WDI are based on LCU, where all use different base years
# 4.) all 4 of these PWT, WDI-LCU, Oxford-LCU, IMF-LCU are in real terms
# 5.) only Oxford amongst these 4 is at quarterly level, rest are at annual level

# [6:41 pm] George Yang
# oxford is in millions, IMF is in billions, WDI is just in dollars
# ------------

# there is almost 0.1% more gdp values for all admin2 month pairs
# i.e. 484,249 more rows of gdp data
# ------------------- Improvement from earlier -----


# negative in admin2 
table(admn_jul$sum_pix<0)
# FALSE    TRUE 
# 4684025  158470 

# make negatives as 0
admn_jul <- data.table(admn_jul)
admn_jul$sum_pix_clb <- ifelse(admn_jul$sum_pix<0,0,admn_jul$sum_pix)

# create oxford annual GDP variable
admn_jul[,ox_anrgdp_lcu := mean(ox_rgdp_lcu,na.rm=T), by = .(iso3c,name_0,gid_1,name_1,gid_2, year)]    # to include the result in the data table


# aggreagte this to country year level
ctyr_2 <- admn_jul[,.(sum_pix = sum(sum_pix, na.rm=T), pol_area = sum(pol_area, na.rm=T),
                   sum_pix_clb = sum(sum_pix_clb, na.rm=T), 
                   imf_rgdp_lcu = mean(imf_rgdp_lcu, na.rm=T), 
                   pwt_rgdpna = mean(pwt_rgdpna, na.rm=T),
                   WDI = mean(WDI, na.rm=T), 
                   ox_anrgdp_lcu = mean(ox_anrgdp_lcu, na.rm=T)),
                by = .(iso3c,year)]


# checks
length(unique(ctyr_2$iso3c))  # 187
length(unique(ctyr_2$year))   # 9
ctyr_2$year_f <- as.factor(ctyr_2$year)
ctyr_2$iso3c_f <- as.factor(ctyr_2$iso3c)
ctyr_2$sum_pix_clb_area <- ctyr_2$sum_pix_clb/ctyr_2$pol_area



# check reg
r6 <- feols(log(ox_anrgdp_lcu) ~ log(sum_pix_clb_area)|iso3c_f +year_f, model='within',data=ctyr_2)
r7 <- feols(log(ox_anrgdp_lcu) ~ log(sum_pix/pol_area)|iso3c_f +year_f, model='within',data=ctyr_2)
summary(r6) # Matched
summary(r7) # Matched
etable(r4, r5, r6)


# check reg with selected countries
# GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
length(unique(ctyr_2$iso3c))  # 187
ctyr_3 <- ctyr_2[!ctyr_2$iso3c %in% c('GNQ','BHR','SGP','HKG')]
length(unique(ctyr_3$iso3c))  # 184
r8 <- feols(log(ox_anrgdp_lcu) ~ log(sum_pix_clb_area)|iso3c_f +year_f, model='within',data=ctyr_3)
summary(r8)
r9 <- feols(log(ox_anrgdp_lcu) ~ log(sum_pix)|iso3c_f +year_f, model='within',data=ctyr_3)
r10 <- feols(log(ox_anrgdp_lcu) ~ log(sum_pix/pol_area)|iso3c_f +year_f, model='within',data=ctyr_3)
etable(r8, r9, r10)

# check reg with other gdp
r11 <- feols(log(imf_rgdp_lcu) ~ log(sum_pix_clb_area)|iso3c_f +year_f, model='within',data=ctyr_3)
r12 <- feols(log(pwt_rgdpna) ~ log(sum_pix_clb_area)|iso3c_f +year_f, model='within',data=ctyr_3)
r13 <- feols(log(WDI) ~ log(sum_pix_clb_area)|iso3c_f +year_f, model='within',data=ctyr_3)
etable(r11, r12, r13)


# check reg with for improved fit countries



# ========================================================================================












# manual checks on newly 1july data
# ========================================================================================
# for checks select a country
sam <- admn_jul[admn_jul$iso3c == "IND",]
ss1 <- sam[,c("iso3c","name_0","gid_1","name_1","gid_2","year","month","time",
              "ox_rgdp_lcu","imf_rgdp_lcu","WDI","sum_pix_clb","pwt_rgdpna")]
ss1[,ox_anrgdp_lcu := mean(ox_rgdp_lcu), by = .(iso3c,name_0,gid_1,name_1,gid_2, year)]    # to include the result in the data table
# ========================================================================================



# checks to see why the earlier 0.12 and 0.08 dont match
# ========================================================================================
# just merge oxford gdp for both
m1 <- merge(x=ctyr[,c("iso3c","year","ox_rgdp_lcu","sum_pix_clb_area")],
               y=reg_dt[,c("iso3c","year","Oxford",'sum_pix')], 
               by= c("iso3c","year"))
# change seems to be more in y than x
# also the regression is taking 
# and aggregation is going wrong since it is repeated for different values
names(ctyr_2)[names(ctyr_2) == "ox_rgdp_lcu"] <- "ox_rgdp_lcu_new"
names(ctyr_2)[names(ctyr_2) == "sum_pix_clb_area"] <- "sum_pix_clb_area_new"

# just merge oxford gdp for both
mtest <- merge(x=ctyr_2[,c("iso3c","year","ox_rgdp_lcu_new","sum_pix_clb_area_new")],
               y=m1, 
               by= c("iso3c","year"))
# change seems to be more in y than x
# also the regression is taking 
# and aggregation is going wrong since it is repeated for different values
# ========================================================================================



# replace negative by previous month
# ========================================================================================
#




# ========================================================================================




