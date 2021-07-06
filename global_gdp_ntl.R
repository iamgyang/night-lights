library('sp'); library('maptools');library('data.table');library(plotly)
library(ggplot2); library(readstata13); library(readxl); library(zoo); library(scales)
library(RColorBrewer); library(ggthemes); library(rgdal)
options(scipen=99)
source("http://peterhaschke.com/Code/multiplot.R")

# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------
#                ------------------- Global GDP & NTL ------------------ 
# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------


# GDP and NTL country level data
# ========================================================================================
# IMF GDP for 65 countries and NTL
ggdp_1 <- read.dta13('/Users/parthkhare/Desktop/CGD/Projects/Globalsat/data/HF indicators/Country GDP/ntl_natl_gdp.dta')
table(ggdp_1$year)
summary(ggdp_1$sum_pix)

ggdp_1 = ggdp_2
# problems
ggdp_err <- ggdp_1[ggdp_1$sum_pix < 1,]
View(ggdp_err)
table(ggdp_err$iso3c)

# remove 31 year month and country pairs with negative nightlights sum
ggdp <- ggdp_1[ggdp_1$sum_pix_sum > 1,]
names(ggdp)[names(ggdp) == 'sum_pix_sum'] <- 'sum_pix'
names(ggdp)[names(ggdp) == 'quarter'] <- 'quart'
summary(ggdp$sum_pix)
ggdp$year_quar <- paste0(ggdp$year,'-',ggdp$quart)

# correlation plots 
gyp <- subset(ggdp, year==c('2013','2014','2015'))
gyp <- subset(ggdp, year==c('2016','2017','2018'))
gyp <- subset(ggdp, year==c('2019','2020'))

# corr plots by yq
cats <- unique(gyp$year_quar)
cats <- sort(cats)
plot_corr <- list()
for(i in 1: length(cats))
{
  dts <- subset(gyp, year_quar == cats[i])
  cp <- ggplot(dts, aes(log(sum_pix), log(nom_gdp))) + geom_point() +
    # geom_point(aes(colour=factor(dts$iso3c))) +
    xlab('') + ylab('') +
    theme_minimal() + ggtitle(paste0('Corr:',dts$year_quar)) +
    geom_smooth(method=lm, se=F, linetype="dashed",color="red", size=0.5) +
    theme(legend.position = "none")
  cp <- cp + scale_alpha(guide = 'none')
  plot_corr[[i]] <- cp
}
print(multiplot(plotlist = plot_corr, cols = 2))
# ========================================================================================




# Regression
# ========================================================================================
# panel
coplot(nom_gdp ~ year|iso3c, type="l", data=ggdp) # Lines
cty <- unique(ggdp$iso3c)
i = 33
gdp_sub <- subset(ggdp, iso3c %in% cty[1:20])
coplot(log(nom_gdp) ~ year|iso3c, type="l", data=gdp_sub) # Lines
coplot(log(sum_pix) ~ year|iso3c, type="l", data=gdp_sub) # Lines
dev.off()

# scatter-plot
library(car)
scatterplot(log(nom_gdp)~year|iso3c, boxplots=FALSE, smooth=TRUE, reg.line=FALSE, data=gdp_sub)


# heteroganetiy in means
library(gplots)
plotmeans(log(nom_gdp) ~ iso3c, main="Heterogeineity in ln GDP across countries", data=ggdp)
plotmeans(log(sum_pix) ~ iso3c, main="Heterogeineity in lnNTL across countries", data=ggdp)

# heteroganetiy across years
plotmeans(log(nom_gdp) ~ year, main="Heterogeineity across years", data=ggdp)

# ols I
ols <-lm(nom_gdp ~ sum_pix, data=ggdp)
summary(ols)
yhat <- ols$fitted
plot(ggdp$sum_pix, ggdp$nom_gdp, pch=19, xlab="ntl", ylab="gdp")
abline(lm(ggdp$nom_gdp~ggdp$sum_pix),lwd=3, col="red")

# ols I
lols <-lm(log(nom_gdp) ~ log(sum_pix), data=ggdp)
summary(lols)
lyhat <- lols$fitted
plot(log(ggdp$sum_pix), log(ggdp$nom_gdp), pch=20, xlab="ntl", ylab="gdp")
abline(lm(log(ggdp$nom_gdp)~log(ggdp$sum_pix)),lwd=3, col="red")

# fe model
fixed.dum <-lm(log(nom_gdp) ~ log(sum_pix) + factor(iso3c) - 1, data=ggdp)
summary(fixed.dum)

feyhat <- fixed.dum$fitted
library(car)
scatterplot(feyhat~log(ggdp$nom_gdp)|ggdp$iso3c, boxplots=FALSE, 
            xlab="log gdp", ylab="yhat",smooth=FALSE)
abline(lm(Panel$y~Panel$x1),lwd=3, col="red")


# first differences: using quarter i
fd_plot <- list()
for(i in 1:4)
{
  fd <- subset(ggdp, quart == i)
  fd$ln_nomgdp <- log(fd$nom_gdp)
  fd$ln_sumntl <- log(fd$sum_pix)
  fd <- fd[,c('iso3c','year_quar','ln_sumntl','ln_nomgdp')]
  
  str_qr <- paste0("-",i)
  fdw1 <- dcast(fd, iso3c ~ year_quar,value.var='ln_nomgdp')
  names(fdw1)[names(fdw1) %like% str_qr] <- paste0(names(fdw1)[names(fdw1) %like% str_qr],'_',"gdp")
  fdw2 <- dcast(fd, iso3c ~ year_quar,value.var='ln_sumntl')
  names(fdw2)[names(fdw2) %like% str_qr] <- paste0(names(fdw2)[names(fdw2) %like% str_qr],'_',"ntl")
  fdw <- merge(fdw1, fdw2, by="iso3c")
  
  str_qr_g20 <- paste0('2020-',i,'_gdp');   str_qr_g13 <- paste0('2013-',i,'_gdp')
  str_qr_n20 <- paste0('2020-',i,'_ntl');   str_qr_n13 <- paste0('2013-',i,'_ntl')
  fdw$fdgdp.20_13 <- fdw[,str_qr_g20] - fdw[,str_qr_g13]
  fdw$fdntl.20_13 <- fdw[,str_qr_n20] - fdw[,str_qr_n13]
  
  d=ggplot(fdw, aes(fdntl.20_13,fdgdp.20_13)) + geom_point(aes(col=iso3c)) +
    geom_smooth(method = "glm",se=F, linetype="dashed",color="black", size=0.5) +
    geom_smooth(method = "lm",se=F, linetype="dashed",color="red", size=0.5) + 
    #geom_smooth(method = "loess",se=F, linetype="dashed",color="blue", size=0.5) + 
    # geom_smooth(method = "lm", mapping = aes(weight = fdntl.20_13), 
    #             se=F, linetype="dashed",color="red", size=0.5) + 
    xlab(paste0('ln',str_qr_n20,'- ln',str_qr_n13)) + 
    ylab(paste0('ln',str_qr_g20,'- ln',str_qr_g13)) + ggtitle(paste0('quar-',i)) +
    theme(legend.position = "none")
  fd_plot[[i]] <- d
}
print(multiplot(plotlist = fd_plot, cols = 2))

# how can one preare for data nationalism, 
# governments are becoming data centralized and increasingly shy of sharing granular, frequent admin data


# Check aggregation
# check missing NA's
# run first differences regression
# finalise ppt


# ========================================================================================


# Social Connectedness Data
# ========================================================================================
# Country level connectness
scc <- read.table('/Users/parthkhare/Desktop/CGD/Projects/Globalsat/data/SCI Facebook data/2020-12-16_country_country.tsv')
names(scc)[names(scc) == "V1"] <- as.character(scc[1,1])
names(scc)[names(scc) == "V2"] <- as.character(scc[1,2])
names(scc)[names(scc) == "V3"] <- as.character(scc[1,3])
scc <- scc[-1,]
scc$user_loc <- as.character(scc$user_loc)

# SC connection average: ADMIN0 connection strength
scc <- data.table(scc)
scc$scaled_sci <- as.numeric(as.character(scc$scaled_sci))
ad0cs <- scc[,.(conn_str = mean(scaled_sci)), by=.(user_loc)]

# country key matching
library(countrycode)
guess_field(c('DZA', 'CAN', 'DEU'))
guess_field(unique(scc$user_loc))  # ecb names
guess_field(unique(ggdp$iso3c))    # iso3c names

# create key
# m1=countrycode(unique(scc$user_loc), origin = 'ecb', destination = 'iso.name.en')
# m2=countrycode(unique(ggdp$iso3c), origin = 'iso3c', destination = 'iso.name.en')
# table(m1 %in% m2) # 64 matches/65 countries
ad0cs$user_loc_isonm <- countrycode(ad0cs$user_loc, origin = 'ecb', destination = 'iso.name.en')
ggdp$iso3c_nm <- countrycode(ggdp$iso3c, origin = 'iso3c', destination = 'iso.name.en')
table(ad0cs$user_loc_isonm %in% ggdp$iso3c_nm)

# merge
gns <- merge(x=ggdp,y=ad0cs,by.x='iso3c_nm',by.y='user_loc_isonm')

# ========================================================================================


