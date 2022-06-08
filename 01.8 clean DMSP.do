// DMSP from Aid Data William and Mary: Seth Goodman ------------------------------------

// This file creates agggregates from the DMSP data. 
import delimited "$raw_data/DMSP ADM2/dmsp 1992-2013.csv", encoding(UTF-8) clear
rename *, lower
destring sum_pix_dmsp_ad, replace ignore(NA)
keep objectid sum_pix_dmsp_ad pol_area year
tempfile dmsp_prior_merge
save `dmsp_prior_merge'

// get iso3c and ADM1 label from the other files
use "$input/bm_adm2_month.dta", clear
keep gid_1 gid_2 objectid iso3c
gduplicates drop
check_dup_id "objectid"
tempfile adm_labels
save `adm_labels'

// merge the two
clear
use `dmsp_prior_merge'
mmerge objectid using `adm_labels'
drop _merge
save "$input/dmsp_adm2_year.dta", replace

// collapse by year and country
gcollapse (sum) sum_pix_dmsp_ad pol_area, by(iso3c year gid_1)
drop if mi(iso3c) | mi(year)
check_dup_id "year gid_1"
save "$input/dmsp_adm1_year.dta", replace

// collapse by year and country
gcollapse (sum) sum_pix_dmsp_ad pol_area, by(iso3c year)
drop if mi(iso3c) | mi(year)
save "$input/dmsp_iso3c_year.dta", replace

.