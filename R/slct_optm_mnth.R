library('sp'); library('maptools');library('data.table');library(plotly)
library(ggplot2); library(readstata13); library(readxl); library(zoo); library(scales)
library(RColorBrewer); library(ggthemes); library(rgdal); library(countrycode)
library(data.table)
options(scipen=99)
source("http://peterhaschke.com/Code/multiplot.R")

# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------
#                ------------------- Find optimal months ------------------ 
# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------


# Admin2 nightlights and GDP data
# ========================================================================================
# load admin2 data
load('/Users/parthkhare/Desktop/CGD/Projects/Globalsat/data/extracted viirs/compiled global ntl/NTL_GDP_month_ADM2_17Jun21.RData')
dim(nlgdad2)
nlgdad2 <- data.table(nlgdad2)
length(unique(nlgdad2$gid_2))
table(is.na(nlgdad2$gid_2))

# # make negatives as 0
nlgdad2$sum_pix_clb <- ifelse(nlgdad2$sum_pix<0,0,nlgdad2$sum_pix)
class(nlgdad2)

table(is.na(nlgdad2$imf_quart_rgdp))/nrow(nlgdad2)
# FALSE      TRUE 
# 0.5680683 0.4319317 
table(is.na(nlgdad2$pwt_rgdpna))/nrow(nlgdad2)
# FALSE      TRUE 
# 0.8531619 0.1468381 
table(is.na(nlgdad2$WDI))/nrow(nlgdad2)
# FALSE      TRUE 
# 0.8667354 0.1332646 
table(is.na(nlgdad2$ox_rgdp_lcu))/nrow(nlgdad2)
# FALSE      TRUE 
# 0.8813938 0.1186062 
table(is.na(nlgdad2$imf_rgdp_lcu))/nrow(nlgdad2)
# FALSE       TRUE 
# 0.97757664 0.02242336 
# ========================================================================================






# Method I: GBM
# ========================================================================================
# GBM results from AWS
# --------------------------------
load('/Users/parthkhare/Desktop/CGD/Projects/Globalsat/data/HWS & country level/optimal months gbm aws/gbm_res_23Jun21.RData')
dim(feat1)
feat1 <- feat1[!feat1$iso3c %in% "ABC",]

i2 <- ini
afg <- i2
gbmerge <- afg

ini <- gbmerge
ctynum <- length(unique(feat1$iso3c))

# Check for results consistency
# --------------------------------
# Select country and check the ranking consistency
for(i in 2:150)
{
  ctynm <- unique(feat1$iso3c)[i]
  
  subs <- feat1[feat1$iso3c %in% ctynm,]
  trn <- data.frame(t(subs))
  t1 <- trn[-c(1:5),]
  t1$mon <- row.names(t1)
  rank_gbm <- cbind(t1$mon, sapply(t1[,c(1:5)], rank))
  rank_gbm <- data.frame(rank_gbm)
  names(rank_gbm) <- paste0(names(rank_gbm),"_rk")
  # combine
  gbmrnk <- cbind(t1, rank_gbm)
  gbmrnk$mon <- NULL
  # data type change
  cols.num <- names(gbmrnk)[names(gbmrnk) %like% 'rel.inf']
  gbmrnk[cols.num] <- sapply(gbmrnk[cols.num],as.numeric)
  # means
  gbmrnk$ri_mn <- rowMeans(gbmrnk[,c(1:5)], na.rm=TRUE)
  gbmrnk$rnk_mn <- rowMeans(gbmrnk[,c(7:11)], na.rm=TRUE)

  # create dataset to merge
  gbmerge <- gbmrnk[,c("V1_rk","rnk_mn","ri_mn")]
  gbmerge$month <- substr(gbmerge$V1_rk,13,14)
  gbmerge$iso3c <- ctynm
  gbmerge$ri_nrm <- normalize(gbmerge$ri_mn)
  gbmerge$V1_rk <- NULL
  
  # final
  ini <- rbind(ini, gbmerge)
}
length(unique(ini$iso3c))  # 148 countries


names(ini)
merge_rnk <- ini
merge_rnk$rnk_mn <- NULL; #merge_rnk$ri_mn <- NULL

# merge with admin2 
nlgb <- merge(x=data.frame(nlgdad2), y=merge_rnk, by=c("iso3c","month"))
nlgb <- data.table(nlgb)

nlgb$sum_pix_nrm <- nlgb$sum_pix*nlgb$ri_mn
nlgb$sum_pix_clnrm <- nlgb$sum_pix_clb*nlgb$ri_mn

ntag <- nlgb[,.(sum_pix = sum(sum_pix, na.rm=T), pol_area = sum(pol_area, na.rm=T),
                sum_pix_clb = sum(sum_pix_clb, na.rm=T), 
                sum_pix_nrm = sum(sum_pix_nrm, na.rm=T), 
                sum_pix_clnrm = sum(sum_pix_clnrm, na.rm=T), 
                imf_quart_rgdp = sum(imf_quart_rgdp, na.rm=T),
                pwt_rgdpna = sum(pwt_rgdpna, na.rm=T),
                WDI = sum(WDI, na.rm=T),
                ox_rgdp_lcu = sum(ox_rgdp_lcu, na.rm=T)),
               by = .(iso3c,year)]

ntag$iso3c_f <- as.factor(ntag$iso3c)
ntag$year_f <- as.factor(ntag$year)

re3 <- feols(log(ox_rgdp_lcu) ~ log(sum_pix_clb/pol_area) |iso3c_f +year_f, 
            model='within',data=ntag)
summary(re3)

re3 <- feols(log(ox_rgdp_lcu) ~ log(sum_pix_clnrm/pol_area) |iso3c_f +year_f, 
             model='within',data=ntag)
summary(re3)


m2 <- merge(ntag, neg_rem, by=c("iso3c","month"))


# -------------------------------- THIS WAS RUN ON AWS # --------------------------------

# reshape data: months should be wide
# test <- nlgdad2[10000:20000,]
nladml = dcast(nlgdad2, iso3c + name_0 + gid_1 + name_1 + gid_2 + pol_area +
                imf_rgdp_lcu + WDI + ox_rgdp_lcu + year ~ month,
               value.var = c('sum_pix_clb'))
dim(nladml)
# 
# # clean for missing in Y 
# dfna <- nladml[!is.na(nladml$imf_rgdp_lcu)]
# table(is.na(dfna$imf_rgdp_lcu))
# nrow(nladml)-nrow(dfna)
# 
# # Perform training:
# library(gbm); set.seed(123)
# gbm_clf = gbm(imf_rgdp_lcu ~ sum_pix_1 + sum_pix_2 + sum_pix_3 + sum_pix_4 + sum_pix_5 + 
#                                sum_pix_6 + sum_pix_7 + sum_pix_8 + sum_pix_9 + sum_pix_10 + 
#                                sum_pix_11 + sum_pix_12, 
#               data=dfna, shrinkage = 0.01, verbose =T, n.trees = 5000, 
#               cv.folds = 5, interaction.depth = 3)
# 
# ========================================================================================




# Method II: Variacne in months
# ========================================================================================
# find months with maximum variance

# Country wise selection
ctylist <-  unique(nladml$iso3c)

for(i in 1:length(unique(nladml$iso3c)))
{
  # Subset countries
  sub_cty_na <- nladml[nladml$iso3c == ctylist[i]]
  # Subset non na for IMF
  sub_cty <- sub_cty_na[!is.na(sub_cty_na$imf_rgdp_lcu)]
  # Perform training:
  set.seed(123)
  gbm_imf = gbm(imf_rgdp_lcu ~ sum_pix_clb_1 + sum_pix_clb_2 + sum_pix_clb_3 + sum_pix_clb_4 + sum_pix_clb_5)

}



# ========================================================================================




