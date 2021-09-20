# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------
#                ------------------- Clean NTL_GDP_month_ADM2_17Jun21.RData ------------------ 
# The original file was made by george in .dta file named NTL_GDP_month_ADM2.dta
# the file is saved in the same name
# -------------------------------- XXXXXXXXXXXXXXXXXXXX --------------------------------



# Admin2 nightlights and GDP data
# ========================================================================================
# load admin2 data
load('/Users/parthkhare/Desktop/CGD/Projects/Globalsat/data/extracted viirs/compiled global ntl/NTL_GDP_month_ADM2_17Jun21.RData')
dim(s)

# clean and prepare
s$v1 <- NULL
table(is.na(s$iso3c)) ; length(unique(s$iso3c)) # FALSE, 167
table(s$iso3c == 'NA') # 13650

# 4842495 (earlier 4828845) iso3c and gid_2
# 13650 dont have iso3c


# repair extracted data
# -------------------------------- 
dd <- s[s$iso3c == 'NA',]
table(is.na(dd$iso)); #View(dd)  # 13650
length(unique(dd$iso)) # 21

# 21 countries with 13650 admins2 have gadmid instead 
nlgdad2 <- s

# Assign ISO3 to missing countries
nlgdad2$iso3c <- ifelse(nlgdad2$iso3c == 'NA',nlgdad2$iso, nlgdad2$iso3c) 
table(nlgdad2$iso3c == 'NA') # NONE

# Assign gadmind to gid_2
library(countrycode)
guess_field(unique(dd$gadmid))   # not found conversion to consistent form
table(nlgdad2$gid_2 == 'NA') # 13650
nlgdad2$gid_2 <- ifelse(nlgdad2$gid_2 == 'NA',nlgdad2$gadmid, nlgdad2$gid_2) 
table(nlgdad2$gid_2 == 'NA') # NONE: clear
nlgdad2$gadmid <- NULL; nlgdad2$iso <- NULL; nlgdad2$v1 <- NULL
object.size(nlgdad2)*(1e-6)  # MB
dim(nlgdad2)

save(nlgdad2,file='/Users/parthkhare/Desktop/CGD/Projects/Globalsat/data/extracted viirs/compiled global ntl/NTL_GDP_month_ADM2_17Jun21.RData')
