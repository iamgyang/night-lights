// Right now, we're merging based on the mid-point of the war start period.
// As a future robustness check, merge based on the start point of the war start 
// period, and vary the death cutoff.

// order war data
use "$raw_data/ucdp_war/aggregated_objectID_deaths.dta", clear
sort objectid month year
rename cnf_dur deaths_dur
save "$input/aggregated_objectID_deaths_cleaned.dta", replace

// order natural disasters data
use "$raw_data/Natural Disasters/nat_disaster.dta", clear
sort objectid month year
capture quietly rename no_* ndis_*
tostring(objectid), replace
decode objectid, gen(a)
drop objectid
rename a objectid
gen affected = ndis_affected + ndis_injured + ndis_homeless
keep year month objectid affected dur
rename dur affected_dur
save "$input/nat_disaster_cleaned.dta", replace

// merge in disaster and war data with night lights:
use "$input/NTL_VIIRS_appended_cleaned_all.dta", clear
sort objectid month year 
capture quietly drop _merge
mmerge objectid month year using "$input/aggregated_objectID_deaths_cleaned.dta"
mmerge objectid month year using "$input/nat_disaster_cleaned.dta"

keep objectid iso3c del_sum_pix del_sum_area sum_pix sum_area year month deaths *dur _merge affected
drop _merge
fillin objectid year month
replace deaths = 0 if deaths == .
replace affected_dur = 0 if affected_dur == .
replace deaths_dur = 0 if deaths_dur == .
replace affected = 0 if affected == .
drop if missing(objectid)
check_dup_id "objectid year month"

// get outcome variable:
g ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
g ln_sum_pix_area = ln(sum_pix/sum_area)
drop del_sum_pix del_sum_area sum_pix sum_area _fillin sum_pix sum_area

// encode categorical variables (numeric --> categorical)
foreach i in year {
	gen str_`i' = string(`i')
	encode str_`i', gen(cat_`i')
	drop str_`i'
}

// encode categorical variables (character --> categorical)
foreach i in objectid {
    encode `i', gen(cat_`i')
}

// month has to be ordered
gen str_month = string(month)
label define str_month 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10" 11 "11" 12 "12"
encode str_month, generate(cat_month) label(str_month) 
drop str_month

save "$input/war_nat_disaster_event_prior_to_cutoff.dta", replace

// GET A TEST SAMPLE ----------------------------------------------------
use "$input/war_nat_disaster_event_prior_to_cutoff.dta", clear

// get a sample of the data
preserve
keep if (affected != 0  & !missing(affected)) | ///
(deaths != 0  & !missing(deaths))
keep objectid
gduplicates drop
gen keep_var = 1
tempfile keep_merge
save `keep_merge'
restore

mmerge objectid using `keep_merge'
keep if keep_var == 1
drop keep_var

gen n = _n
keep if n <= 50000
save "$input/sample_war_nat_disaster_event_prior_to_cutoff.dta", replace











