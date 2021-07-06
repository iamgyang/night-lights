library('sp'); library('maptools');library('data.table');library(plotly)
library(ggplot2); library(readstata13); library(readxl); library(zoo); library(scales)
library(RColorBrewer); library(ggthemes); library(rgdal)
options(scipen=99)
source("http://peterhaschke.com/Code/multiplot.R")

# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------
#             ------------------- Storeygard Replication ------------------ 
# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------



# HWS regressions on VIIRS
# Data made by George: version negative removed and not removed
# Date: 17june 2021
# ========================================================================================
library(plm); library(fixest)

library(fixest)
# Negatives removed at admin2 level
# --------------------------------
neg_rem <- read.csv('/Users/parthkhare/Desktop/CGD/Projects/Globalsat/data/HWS & country level/merged_month_gid_2_17jun HWS reg replication.csv')

# **************** reg 3 **************** USE THIS
r3 <- feols(log_delt_Oxford_1 ~ log_delt_sum_pix_1|iso3c +year_f, model='within',data=neg_rem)

r3 <- feols(log_delt_Oxford_1 ~ log_delt_sum_pix_1|iso3c +year_f, model='within',data=neg_rem)

r3 <- feols(log(Oxford) ~ log(sum_pix)|iso3c +year_f, data=neg_rem)
neg_rem$sum_pix_tot <- neg_rem$sum_pix*neg_rem$sum_area
r3 <- feols(log(Oxford) ~ log(sum_pix_tot/sum_area)|iso3c +year_f, data=neg_rem)
summary(r3)
# **************** reg 3 **************** USE THIS

# feols gives same results as xtreg and reghdfe in stata

# reg 1
r1 <- plm(log(Oxford) ~ log(sum_pix), 
          index=c('iso3c','year_f'), model='within',data=neg_rem)
r2 <- plm(log_delt_Oxford_1 ~ log_delt_sum_pix_1, 
          index=c('iso3c','year_f'), model='within',data=neg_rem)
r4 <- lm(log_delt_Oxford_1 ~ log_delt_sum_pix_1 + iso3c + year_f,data=neg_rem)

summary(r1); summary(r2); summary(r4)


# Negatives removed at admin2 level
# --------------------------------
neg_not_rem <- read.csv('/Users/parthkhare/Desktop/CGD/Projects/Globalsat/data/HWS & country level/merged_none_none_17jun HWS reg replication.csv')
neg_not_rem$year_f <- as.factor(neg_not_rem$year)

# **************** reg 3 **************** USE THIS
rg3 <- feols(log_delt_Oxford_1 ~ log_delt_sum_pix_1|iso3c+year_f,data=neg_not_rem)
summary(rg3)
# **************** reg 3 **************** USE THIS

# fe regs 1
rg1 <- plm(log_delt_Oxford_1 ~ log_delt_sum_pix_1, 
          index=c('iso3c','year_f'), model='within',data=neg_not_rem)
rg2 <- plm(log(Oxford) ~ log(sum_pix), 
          index=c('iso3c','year_f'), model='within',data=neg_not_rem)
r4 <- lm(log_delt_Oxford_1 ~ log_delt_sum_pix_1 + iso3c + year_f,data=neg_not_rem)
summary(rg1) ;summary(rg2); summary(r4)
# ========================================================================================





# -----------CALL ---------------------
# -----------
# feols gives same results as xtreg and reghdfe in stata
# --------------------------------




















# Load merged data
# ========================================================================================
# imf ntl oxford and pwt
gdpntl <- read.dta13('/Users/parthkhare/Desktop/CGD/Projects/Globalsat/data/HF indicators/Country GDP/imf_pwt_oxf_ntl.dta')

# data check and clean
length(unique(gdpntl$iso3c))
length(unique(gdpntl$time))
table(is.na(gdpntl$sum_sumlight))
# FALSE  TRUE 
# 17535 12954 

# Subset NA records
gn <- gdpntl[!is.na(gdpntl$sum_sumlight),]
dim(gn)
# check countries and time periods
table(gn$iso3c)  # all have 105 months --  balanced panel 
length(unique(gn$iso3c)) # 167
summary(gn$sum_sumlight)



# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------
# ------------------- 3 types of aggregation to account for negative sum of lights ------------------ 
# convert negatives to 0
# remove country months with negative lights
# remove admin2 with negative lights
# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------



# Subset Negative sum of lights: unbalanced panel
gnp <- gn[gn$sum_sumlight > 0,]
dim(gnp)
table(gnp$iso3c)   # all have 105 months --  unbalanced panel
length(unique(gnp$iso3c))
summary(gnp$sum_sumlight)


# Annual data summation
gnp <- data.table(gnp)

# use mean to account for missing months
gnpa <- gnp[,.(ssum_sumlight=sum(sum_sumlight, na.rm=T),msum_sumlight=mean(sum_sumlight, na.rm=T),
                    smean_sumlight=sum(mean_sumlight, na.rm=T),mmean_sumlight=mean(mean_sumlight, na.rm=T),
                    mgini_sumlights=mean(gini_sumlights, na.rm=T),mmean_stdlights=mean(mean_stdlights,na.rm=T),
                    sum_area = mean(sum_area, na.rm=T),
                    nom_gdp = sum(nom_gdp, na.rm=T),
                    rgdp = sum(rgdp, na.rm=T),
                    ox_rgdp_lcu = mean(ox_rgdp_lcu, na.rm=T),
                    pwt_rgdpna = mean(pwt_rgdpna, na.rm=T),
                    imf_rgdp_lcu = mean(imf_rgdp_lcu, na.rm=T)),by = .(iso3c, iso3c_nm, year)]


# ========================================================================================


summary(gnpa$imf_rgdp_lcu)
gnpa_1 <- gnpa[!gnpa$pwt_rgdpna ==0,]  # taking country where pwt gdo data is present
gnpa_1 <- gnpa[!gnpa$ox_rgdp_lcu ==0,]
gnpa_1 <- gnpa[!gnpa$imf_rgdp_lcu ==0,]
table(gnpa_1$ox_rgdp_lcu==0)
table(gnpa_1$imf_rgdp_lcu==0)



# Regressions
# ========================================================================================
# ols I
ols <-lm(log(pwt_rgdpna) ~ log(ssum_sumlight/sum_area), data=gnpa_1)
summary(ols)
yhat <- ols$fitted
plot(log(gnpa_1$ssum_sumlight), log(gnpa_1$pwt_rgdpna), pch=19, xlab="ntl", ylab="gdp")
abline(lm(log(gnpa_1$pwt_rgdpna)~log(gnpa_1$ssum_sumlight)),lwd=3, col="red")

# ols I
ols <-lm(log(ox_rgdp_lcu) ~ log(ssum_sumlight), data=gnpa_1)
summary(ols)
yhat <- ols$fitted
plot(log(gnpa_1$ssum_sumlight), log(gnpa_1$ox_rgdp_lcu), pch=19, xlab="ntl", ylab="gdp")
abline(lm(log(gnpa_1$ox_rgdp_lcu)~log(gnpa_1$ssum_sumlight)),lwd=3, col="red")

# ols I
ols <-lm(log(imf_rgdp_lcu) ~ log(ssum_sumlight), data=gnpa_1)
summary(ols)
yhat <- ols$fitted
plot(log(gnpa_1$ssum_sumlight), log(gnpa_1$imf_rgdp_lcu), pch=19, xlab="ntl", ylab="gdp")
abline(lm(log(gnpa_1$imf_rgdp_lcu)~log(gnpa_1$ssum_sumlight)),lwd=3, col="red")
# ========================================================================================





# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------
# ------------------- 3 types of aggregation to account for negative sum of lights ------------------ 
# convert negatives to 0
# remove country months with negative lights
# remove admin2 with negative lights
# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------



# Regressions
# ========================================================================================
# ols I
ols <-lm(log(PWT) ~ log(sum_sumlight_rmvad2/sum_area), data=gdp_ntl_neg)
summary(ols)
yhat <- ols$fitted
plot(log(gdp_ntl_neg$sum_sumlight_rmvad2), log(gdp_ntl_neg$PWT), pch=19, xlab="ntl", ylab="gdp")
abline(lm(log(gdp_ntl_neg$PWT)~log(gdp_ntl_neg$sum_sumlight_rmvad2)),lwd=3, col="red")

# ols I
ols <-lm(log(Oxford) ~ log(sum_sumlight_rmvad2/sum_area), data=gdp_ntl_neg)
summary(ols)
yhat <- ols$fitted
plot(log(gdp_ntl_neg$sum_sumlight_rmvad2), log(gdp_ntl_neg$Oxford), pch=19, xlab="ntl", ylab="gdp")
abline(lm(log(gdp_ntl_neg$Oxford)~log(gdp_ntl_neg$sum_sumlight_rmvad2)),lwd=3, col="red")

# ols I
ols <-lm(log(IMF_quart) ~ log(sum_sumlight_rmvad2/sum_area), data=gdp_ntl_neg)
summary(ols)
yhat <- ols$fitted
plot(log(gdp_ntl_neg$sum_sumlight_rmvad2), log(gdp_ntl_neg$IMF_quart), pch=19, xlab="ntl", ylab="gdp")
abline(lm(log(gdp_ntl_neg$IMF_quart)~log(gdp_ntl_neg$sum_sumlight_rmvad2)),lwd=3, col="red")
# ========================================================================================

install.packages('fixest')
library('fixest')

# Regressions
# ========================================================================================
nl_ols = feols(log(Oxford) ~ log(sum_sumlight_rmvad2/sum_area) | iso3c + year, gdp_ntl_neg)
nl_ols



library(MASS)
rlm = rlm(log(Oxford) ~ log(sum_sumlight_rmvad2/sum_area) + iso3c + year, gdp_ntl_neg)
summary(rlm)


nl_ols = feols(log(Oxford) ~ log(sum_pix_month_gid_2/sum_area) + log((sum_pix_month_gid_2/sum_area)^2) | iso3c + year, gdp_ntl_neg)
nl_ols

summary(gdp_ntl_neg$sum_sumlight_rmvad2)
summary(gdp_ntl_neg$sum_pix_month_gid_2)




nl_ols = feols(log(Oxford) ~ log(sum_pix_month_gid_2/sum_area) | iso3c + year, gdp_ntl_neg)

feols(log(Oxford) ~ log(sum_pix_year_iso3c/sum_area) | iso3c + year, gdp_ntl_neg)
feols(log(Oxford) ~ log(sum_pix_year_iso3c/sum_area) | iso3c + year, gdp_ntl_neg)


nl_ols = feols(log(PWT) ~ log(sum_sumlight_rmvad2/sum_area) | iso3c + year, gdp_ntl_neg)
# ========================================================================================




# try just one year
# ========================================================================================
# log log gdp and ntl



yrsl <- '2017'
for(yrsl in 2012:2019)
{
  sub_chk <- gdp_ntl_neg[gdp_ntl_neg$year == yrsl,]
  
  e = ggplot(sub_chk, aes(log(PWT), log(sum_pix_month_gid_2))) + 
    geom_point(colour='red',size=0.5) + geom_smooth(method='lm',se=F,size=0.5) + 
    theme_minimal() + ylab('Log NL') + xlab('Log GDP PWT') + ggtitle(yrsl) +
    geom_text(aes(label=iso3c),hjust=0.5, vjust=-0.7, size=2)
  
  print(e)
}

ggplot(sub_chk, aes(log(Oxford), log(sum_pix_month_gid_2))) + 
  geom_point(colour='red',size=0.5) + geom_smooth(method='lm',se=F,size=0.5) + 
  theme_minimal() + ylab('Log NL') + xlab('Log GDP Oxford') +
  geom_text(aes(label=iso3c),hjust=0.5, vjust=-0.7, size=2)


ggplot(sub_chk, aes(log(IMF_WEO), log(sum_pix_month_gid_2))) + 
  geom_point(colour='red',size=0.5) + geom_smooth(method='lm',se=F,size=0.5) + 
  theme_minimal() + ylab('Log NL') + xlab('Log GDP IMF_WEO') +
  geom_text(aes(label=iso3c),hjust=0.5, vjust=-0.7, size=2)

ggplot(sub_chk, aes(log(IMF_quart), log(sum_pix_month_gid_2))) + 
  geom_point(colour='red',size=0.5) + geom_smooth(method='lm',se=F,size=0.5) + 
  theme_minimal() + ylab('Log NL') + xlab('Log GDP IMF_quart') +
  geom_text(aes(label=iso3c),hjust=0.5, vjust=-0.7, size=2)


# ========================================================================================












# Global Extraction
# ========================================================================================
gb <- readShapeSpatial('/Users/parthkhare/Data/World Admin/TM_WORLD_BORDERS-0.3/TM_WORLD_BORDERS-0.3.shp')
dim(gb)
length(unique(gb$ISO3)) # 246

table(unique(gb$ISO3) %in% unique(gdpntl$iso3c))
# ========================================================================================
