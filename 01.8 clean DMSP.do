// DMSP from Aid Data William and Mary: Seth Goodman ------------------------------------

// This file creates agggregates from the DMSP data. 
use "$raw_data/raw-data/DMSP ADM2/dmsp 1992-2013.csv", clear
rename *, lower
keep objectid sum_pix_dmsp_aiddata pol_area year

// get iso3c from the other files

save "$input/dmsp_adm2_year.dta", replace
use "$input/bm_adm2_month.dta", clear

// collapse by year and country
gcollapse (sum) sum_pix_dmsp_aiddata pol_area, by(iso3c year)
drop if mi(iso3c) | mi(year)
save "$input/bm_iso3c_year.dta", replace

.