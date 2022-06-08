// DMSP from Aid Data William and Mary: Seth Goodman ------------------------------------

// This file creates agggregates from the DMSP data. 
import delimited "$raw_data/DMSP ADM2/dmsp 1992-2013.csv", encoding(UTF-8) clear
rename *, lower
destring sum_pix_dmsp_ad, replace ignore(NA)
keep objectid gid_0 gid_1 gid_2 sum_pix_dmsp_ad pol_area year
rename gid_0 iso3c
check_dup_id "objectid year"
save "$input/dmsp_adm2_year.dta", replace

// collapse by year and country
foreach i in iso3c year gid_1 {
	drop if mi(`i')
}
gcollapse (sum) sum_pix_dmsp_ad pol_area, by(iso3c year gid_1)
check_dup_id "year gid_1"
save "$input/dmsp_adm1_year.dta", replace

// collapse by year and country
gcollapse (sum) sum_pix_dmsp_ad pol_area, by(iso3c year)
drop if mi(iso3c) | mi(year)
save "$input/dmsp_iso3c_year.dta", replace
.