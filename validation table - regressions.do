// Macros ---------------------------------------------------------------------
foreach user in "`c(username)'" {
	global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
	global hf_input "$root/HF_measures/input/"
	global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
}
set more off 
cd "$hf_input"

foreach i in full_hender overlaps_hender full_same_sample_hender full_gold ///
overlaps_gold full_same_sample_gold {
	global `i' "$hf_input/`i'.xls"
	noisily capture erase "$`i'"	
}

// ------------------------------------------------------------------------

// VIIRS	VIIRS cleaned	DMSP	"VIIRS
// income dummy"	"VIIRS, cleaned, 
// income dummy"	"DMSP
// income dummy"


// full regression Henderson ------------------------------------
use clean_validation_base.dta, clear

foreach gdp_var in ln_WDI ln_PWT {
	foreach light_var in lndn ln_del_sum_pix_area ln_sum_pix_area {
		di "`gdp_var' `light_var'"
		// bare henderson regression: country & year fixed effects
		reghdfe `gdp_var' `light_var', absorb(cat_iso3c cat_yr) vce(cluster cat_iso3c)
		outreg2 using "$full_hender", append ///
			label dec(3) keep (`light_var') ///
			bdec(3) addstat(Adjusted Within R-squared, e(r2_a_within), ///
			Within R-squared, e(r2_within))
		
// 		// with income interaction & income dummy (maintain country-year FE)
// 		reghdfe `gdp_var' i.cat_income c.`light_var'##cat_income, ///
// 			absorb(cat_iso3c cat_yr) vce(cluster cat_iso3c)
// 		outreg2 using "$full_hender", append ///
// 			label dec(3) ///
// 			bdec(3) addstat(Adjusted Within R-squared, e(r2_a_within), ///
// 			Within R-squared, e(r2_within))
	}
}






// regression on overlaps Henderson ------------------------------------
use clean_validation_base.dta, replace
// full regression Henderson on same sample as overlapping ------------------------------------
use clean_validation_base.dta, replace
// full regression Goldberg ------------------------------------
use clean_validation_base.dta, replace
// regression on overlaps Goldberg ------------------------------------
use clean_validation_base.dta, replace
// full regression Goldberg on same sample as overlapping ------------------------------------
use clean_validation_base.dta, replace


















