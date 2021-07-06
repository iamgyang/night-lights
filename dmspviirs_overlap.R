library(readstata13); library(data.table);library(ggplot2);library(fixest)
library(etable)

options(scipen=99)
source("http://peterhaschke.com/Code/multiplot.R")

# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------
#                ------------------- Overlap between years DMSP VIIRS ------------------ 
# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------





# HWS regression: replicate {within R2 is diff using fixest}
# ========================================================================================
# load HWS data at country level
hw2 <- read.dta13('/Users/parthkhare/Desktop/CGD/Projects/Globalsat/data/HWS & country level/global_total_dn_uncal.dta')

# check regression results
hw2$iso3v10 <- as.factor(hw2$iso3v10)
hw2$year <- as.factor(hw2$year)
hwsreg<- feols(lngdpwdilocal ~ lndn| iso3v10 +year, model='within',data=hw2)
etable(hwsreg)    # 191 countries
length(unique(hw2$iso3v10))  # 228

# HWS droppped countries
# drop if iso3v10=="GNQ" | iso3v10=="BHR" | iso3v10=="SGP" | iso3v10=="HKG"
drop_c <- c('GNQ','BHR','SGP','HKG')
hw3 <- hw2[!(hw2$iso3v10 %in% drop_c),]
length(unique(hw3$iso3v10))  # 225
hwsreg1<- feols(lngdpwdilocal ~ lndn| iso3v10 +year, model='within',data=hw3)
etable(hwsreg1)    # 188 countries  -- like main regression

hw3$iso3c <-hw3$iso3v10
# ========================================================================================







# Compare regression from overlapping years
# ========================================================================================
# load HWS raw data at admin 2
hws <- read.csv('/Users/parthkhare/Desktop/CGD/Projects/Globalsat/data/HWS & country level/HWSpaper_Nighttime_Lights_ADM2_1992_2013.csv')
hws <- data.table(hws)
hwa <- hws[,.(sum_dmsp = sum(sum_light, na.rm=T)), by=.(countrycode,year)]
names(hwa)[names(hwa) == 'countrycode'] <- 'iso3c'


# load viirs 17jun george: negatives removed
#  ^^^^^ month)gid2 -- means negatives are removed ^^^^^
vr <- read.csv('/Users/parthkhare/Desktop/CGD/Projects/Globalsat/data/HWS & country level/merged_month_gid_2_17jun HWS reg replication.csv')
vr$sum_vrs <- vr$sum_pix*vr$sum_area

# merge
m1 <- merge(x=hwa, y=vr, by=c('year','iso3c'))
table(m1$year)
m2 <- m1[m1$year %in% c(2012,2013),]
table(m2$year)

# check correlation: 2012
ggplot(m2[m2$year == '2012'], aes(log(sum_dmsp),log(sum_vrs))) + geom_point() +
  geom_smooth(method = 'lm', se=F, size=0.5) + xlab('DMSP: Sum of lights (country)') + 
  ylab(' VIIRS: Sum of light (country)') + ggtitle('2012') + 
  xlim(5,20) + ylim(5,20)
# 2013  
ggplot(m2[m2$year == '2013'], aes(log(sum_dmsp),log(sum_vrs))) + geom_point() +
  geom_smooth(method = 'lm', se=F, size=0.5, colour='red') + xlab('DMSP: Sum of lights (country)') + 
  ylab(' VIIRS: Sum of light (country)') + ggtitle('2013') +
  xlim(5,20) + ylim(5,20)



# Compare regression results
# --------------------------------
# HWS reg using w 2012 and 2013
m2$year_f <- as.factor(m2$year_f)
table(m2$year)

# DMSP
hws1213 <- feols(log_delt_WDI_1 ~ log(sum_dmsp)| iso3c +year_f, model='within',data=m2)
# VIIRS
vrs1213 <- feols(log_delt_WDI_1 ~ log_delt_sum_pix_1| iso3c +year_f, model='within',data=m2)
# results
etable(hws1213, vrs1213)

# DMSP
hws1213 <- feols(log_delt_Oxford_1 ~ log(sum_dmsp)| iso3c +year_f, model='within',data=m2)
# VIIRS
vrs1213 <- feols(log_delt_Oxford_1 ~ log_delt_sum_pix_1| iso3c +year_f, model='within',data=m2)
# results
etable(hws1213, vrs1213)





m13<- m2[m2$year == 2013,]
table(m13$year)



# DMSP
hws13 <- feols(log_delt_Oxford_1 ~ log(sum_dmsp)| iso3c, model='within',data=m13)
# VIIRS
vrs13 <- feols(log_delt_Oxford_1 ~ log_delt_sum_pix_1| iso3c, model='within',data=m13)
# results
etable(hws13, vrs13)
# ========================================================================================




