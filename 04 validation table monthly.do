
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


foreach i in covid_response {
	global `i' "$input/`i'.xls"
	noisily capture erase "`i'.xls"
	noisily capture erase "`i'.txt"
}

// ----------------------------------------------------------------------------

// Oxford COVID ---------
use "$input/covid_oxford_cleaned.dta", clear
collapse (mean) *index, by(iso3c year month)
tempfile ox
save `ox'

// NTL ------------
use "$input/NTL_GDP_month_ADM2.dta", clear
// get monthly - country dataset
keep if !missing(sum_pix)
collapse (sum) sum_pix, by(iso3c year month)
rename sum_pix sum_pix_raw

tempfile ntl_raw
save `ntl_raw'

use "$input/NTL_GDP_month_ADM2.dta", clear
// get monthly - country dataset
keep if !missing(sum_pix)
drop if sum_pix<0
collapse (sum) sum_pix, by(iso3c year month)
rename sum_pix sum_pix_clean

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

foreach i of varlist sum_pix* {
    gen ln_`i' = ln(`i')
	loc lab: variable label `i'
	di "`lab'"
	label variable ln_`i' "Log `lab'"
}

// average restriction
egen restr_avg = rowmean(restr_business restr_health_monitor restr_health_resource restr_mask restr_school restr_social_dist)

// categorical variables
tostring month, replace
foreach i in iso3c month {
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
label variable ln_sum_pix_raw "Log Sum of VIIRS (raw)"
label variable ln_sum_pix_clean "Log Sum of VIIRS (clean)"
save "$input/clean_validation_monthly_base.dta", replace

// Regressions ----------------------------------------------------------------

reghdfe ln_sum_pix_clean cornet* oxcgrt*, absorb(cat_iso3c cat_month) vce(cluster cat_iso3c)
outreg2 using "covid_response.xls", append ///
		label dec(3) keep (cornet* oxcgrt*) ///
		bdec(3) addstat(Countries, e(N_clust), ///
		Adjusted Within R-squared, e(r2_a_within), ///
		Within R-squared, e(r2_within))

reghdfe ln_sum_pix_raw cornet* oxcgrt*, absorb(cat_iso3c cat_month) vce(cluster cat_iso3c)
outreg2 using "covid_response.xls", append ///
		label dec(3) keep (cornet* oxcgrt*) ///
		bdec(3) addstat(Countries, e(N_clust), ///
		Adjusted Within R-squared, e(r2_a_within), ///
		Within R-squared, e(r2_within))

foreach y in ln_sum_pix_raw ln_sum_pix_clean {
	foreach x of varlist cornet* oxcgrt* {
		reghdfe `y' `x', absorb(cat_iso3c cat_month) vce(cluster cat_iso3c)
		
		outreg2 using "covid_response.xls", append ///
		label dec(3) keep (`x') ///
		bdec(3) addstat(Countries, e(N_clust), ///
		Adjusted Within R-squared, e(r2_a_within), ///
		Within R-squared, e(r2_within))
	}
}



































































