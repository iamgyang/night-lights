
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

// Regressions ----------------------------------------------------------------

// at the country-level, are there associations between lights and covid indicators?

use "$input/clean_validation_monthly_base.dta", clear

reghdfe ln_sum_pix cornet* oxcgrt*, absorb(cat_iso3c cat_month) vce(cluster cat_iso3c)
outreg2 using "covid_response.xls", append ///
		label dec(3) keep (cornet* oxcgrt*) ///
		bdec(3) addstat(Countries, e(N_clust), ///
		Adjusted Within R-squared, e(r2_a_within), ///
		Within R-squared, e(r2_within))

reghdfe ln_del_sum_pix cornet* oxcgrt*, absorb(cat_iso3c cat_month) vce(cluster cat_iso3c)
outreg2 using "covid_response.xls", append ///
		label dec(3) keep (cornet* oxcgrt*) ///
		bdec(3) addstat(Countries, e(N_clust), ///
		Adjusted Within R-squared, e(r2_a_within), ///
		Within R-squared, e(r2_within))

foreach y in ln_del_sum_pix ln_sum_pix {
	foreach x of varlist cornet* oxcgrt* {
		reghdfe `y' `x', absorb(cat_iso3c cat_month) vce(cluster cat_iso3c)
		
		outreg2 using "covid_response.xls", append ///
		label dec(3) keep (`x') ///
		bdec(3) addstat(Countries, e(N_clust), ///
		Adjusted Within R-squared, e(r2_a_within), ///
		Within R-squared, e(r2_within))
		
		
		// -------------------------------------------------
		regress `y' `x' i.cat_iso3c##i.cat_month, robust
		
		outreg2 using "covid_response.xls", append ///
		label dec(3) keep (`x') ///
		bdec(3) 
	}
}

// Is there a drop in NTL from covid at the ADM2 level?
use "$input/adm2_month_derived.dta", replace



























































