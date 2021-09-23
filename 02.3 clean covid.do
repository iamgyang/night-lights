
// Coronanet COVID data ------------------------------------------------

// https://github.com/CoronaNetDataScience/corona_index/tree/main/indices

import delimited "$raw_data/Coronanet/all_indices.csv", clear

// get dates
gen year = substr(date_policy, 1, 4)
gen month = substr(date_policy, 6, 2)
gen day = substr(date_policy, 9, 2)
destring(year month day), replace
drop date_policy
drop high_est low_est sd_est

// refactor modtype
replace modtype = "business"        if modtype == "Business Restrictions"
replace modtype = "health_monitor"  if modtype == "Health Monitoring"
replace modtype = "health_resource" if modtype == "Health Resources"
replace modtype = "mask"            if modtype == "Mask Policies"
replace modtype = "school"          if modtype == "School Restrictions"
replace modtype = "social_dist"     if modtype == "Social Distancing"

// reshape wide
reshape wide med_est, i(country year month day) j(modtype, string)
rename med_est* restr_*

// collapse to monthly
collapse (mean) restr_*, by(country year month)

// ISO3C codes
conv_ccode country
replace iso = "CZE" if country == "Czechia"
replace iso = "SWZ" if country == "Eswatini"
replace iso = "XKX" if country == "Kosovo"
replace iso = "COG" if country == "Republic of the Congo"
drop if country == "European Union"
rename iso iso3c

check_dup_id "iso3c year month"
check_dup_id "country  year month"
drop country

save "$input/covid_coronanet_cleaned.dta", replace

// Oxford COVID Data ---------------------------------------------------------

import delimited "$raw_data/Oxford-Covid/OxCGRT_latest.csv", clear
keep if jurisdiction == "NAT_TOTAL"
assert regionname == "" & regioncode == ""
replace countrycode = "XKX" if countryname == "Kosovo"

// make sure have right ISO3C codes
preserve
	keep countrycode countryname
	duplicates drop
	conv_ccode countryname
	assert iso == countrycode if iso != ""
	drop iso
restore

keep countryname countrycode date stringencyindex governmentresponseindex containmenthealthindex economicsupportindex

// date variables
tostring date, gen(date_string)
gen month = substr(date_string, 5, 2)
gen year = substr(date_string, 1, 4)
gen day = substr(date_string, 7, 2)
destring month year day, replace
drop date date_string

// rename 
rename countrycode iso3c
drop countryname

save "$input/covid_oxford_cleaned.dta", replace












































