
// Macros ----------------------------------------------------------------

clear all 
set more off
set varabbrev off
set scheme s1mono
set type double, perm

// CHANGE THIS!! --- Define your own directories:
foreach user in "`c(username)'" {
	global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
}

global code        "$root/HF_measures/code"
global input       "$root/HF_measures/input"
global output      "$root/HF_measures/output"
global raw_data    "$root/raw-data"
global ntl_input   "$root/raw-data/VIIRS NTL Extracted Data 2012-2020"

// CHANGE THIS!! --- Do we want to install user-defined functions?
loc install_user_defined_functions "No"

if ("`install_user_defined_functions'" == "Yes") {
	foreach i in rangestat wbopendata kountry mmerge outreg2 somersd ///
	asgen moss reghdfe ftools fillmissing {
		ssc install `i'
	}
}

// =========================================================================

cd "$input"

// ----------------------------------------------------------------------------
// COUNTRY-MONTH DATASET WITH COVID INDICATORS -----------

// Oxford COVID ---------
use "$input/covid_oxford_cleaned.dta", clear
collapse (mean) *index, by(iso3c year month)
tempfile ox
save `ox'

// NTL ------------
use "$input/NTL_GDP_month_ADM2.dta", clear
// get monthly - country dataset
keep if !missing(sum_pix)
collapse (sum) sum_pix pol_area, by(iso3c year month)
rename sum_pix del_sum_pix

tempfile ntl_raw
save `ntl_raw'

use "$input/NTL_GDP_month_ADM2.dta", clear
// get monthly - country dataset
keep if !missing(sum_pix)
drop if sum_pix<0
collapse (sum) sum_pix pol_area, by(iso3c year month)
rename sum_pix sum_pix

tempfile ntl_clean
save `ntl_clean'

clear
use `ntl_clean'
mmerge iso3c year month using `ntl_raw'

// merge: ---------------------------------------------------------------------
keep if year == 2020
mmerge year month iso3c using "$input/covid_coronanet_cleaned.dta"
check_dup_id "iso3c year month"
drop _merge
keep if year == 2020
mmerge year month iso3c using `ox'
keep if year == 2020
check_dup_id "iso3c year month"
drop _merge

// make extra variables: ----------------------------------------------------

foreach i of varlist *sum_pix* {
    gen ln_`i' = ln(`i')
}

// average restriction
egen restr_avg = rowmean(restr_business restr_health_monitor restr_health_resource restr_mask restr_school restr_social_dist)

// categorical variables
tostring month, replace
gen iso3c_month = iso3c + "_m" + month
foreach i in iso3c month iso3c_month {
	di "`i'"
	encode `i', gen(cat_`i')
}

// rename + label
rename restr* cornet*
rename *index oxcgrt*

label variable cornet_business "business restriction index (Coronanet)"
label variable cornet_health_monitor "health monitoring index (Coronanet)"
label variable cornet_health_resource "health resources index (Coronanet)"
label variable cornet_mask "masking index (Coronanet)"
label variable cornet_school "school restriction index (Coronanet)"
label variable cornet_social_dist "social distancing index (Coronanet)"
label variable oxcgrtstringency "composite stringency index (Oxford)"
label variable oxcgrtgovernmentresponse "government response index (Oxford)"
label variable oxcgrtcontainmenthealth "health containment index (Oxford)"
label variable oxcgrteconomicsupport "economic support index (Oxford)"
label variable ln_sum_pix "Log Sum of VIIRS (raw)"
label variable ln_del_sum_pix "Log Sum of VIIRS (clean)"

save "$input/clean_validation_monthly_base.dta", replace


// ------------------------------------------------------------------------
// ADM2-MONTH DATASET WITH LAGGED & OTHER DERIVED VARIABLES -----------

// NTL ------------
use "$input/NTL_GDP_month_ADM2.dta", clear
// get monthly - country dataset
keep if !missing(sum_pix)
collapse (sum) sum_pix pol_area, by(iso3c objectid year month)
rename (sum_pix pol_area) (del_sum_pix del_sum_area)

tempfile ntl_raw
save `ntl_raw'

use "$input/NTL_GDP_month_ADM2.dta", clear
// get monthly - country dataset
keep if !missing(sum_pix)
drop if sum_pix<0
collapse (sum) sum_pix pol_area, by(iso3c objectid year month)
rename (sum_pix pol_area) (sum_pix sum_area)

tempfile ntl_clean
save `ntl_clean'

clear
use `ntl_clean'
mmerge iso3c objectid year month using `ntl_raw'

check_dup_id "objectid year month"

// per area variables:
gen del_sum_pix_area = del_sum_pix / del_sum_area
gen sum_pix_area = sum_pix / sum_area

// label variables
label variable del_sum_area "VIIRS (cleaned) polygon area"
label variable del_sum_pix "VIIRS (cleaned) sum of pixels"
label variable sum_area "lights (raw) polygon area"
label variable sum_pix "VIIRS (raw) sum of pixels"
label variable sum_pix_area "VIIRS (raw) sum of pixels / area"
label variable del_sum_pix_area "VIIRS (cleaned) pixels / area"

// measure vars
local measure_vars "del_sum_pix sum_pix del_sum_pix_area sum_pix_area"

// log values
foreach i in `measure_vars' {
    gen ln_`i' = ln(`i')
	loc lab: variable label `i'
	di "`lab'"
	label variable ln_`i' "Log `lab'"
}

// first differences on the logged variables
foreach var of varlist ln_* {
	sort objectid year month
    generate g_`var' = `var' - `var'[_n-1] if objectid==objectid[_n-1]
	loc lab: variable label `var'
	di "`lab'"
	label variable g_`var' "Diff. `lab'"
}


// encode categorical variables
tostring (year month), gen(yr mo)

foreach i in objectid yr mo  {
	di "`i'"
	encode `i', gen(cat_`i')
}

drop yr mo _merge

gen after_march = 1 if month >= 3
replace after_march = 0 if month < 3

save "$input/adm2_month_derived.dta", replace




















































