// 0. Preliminaries

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

// CHANGE THIS!! --- Do we want to import nightlights from the tabular raw data? 
// (takes a long time)
global import_nightlights "yes"

// PERSONAL PROGRAMS ----------------------------------------------

// checks if IDs are duplicated
quietly capture program drop check_dup_id
program check_dup_id
	args id_vars
	preserve
	keep `id_vars'
	sort `id_vars'
    quietly by `id_vars':  gen dup = cond(_N==1,0,_n)
	assert dup == 0
	restore
	end

// drops all missing observations
quietly capture program drop naomit
program naomit
	foreach var of varlist _all {
		drop if missing(`var')
	}
	end

// creates new variable of ISO3C country codes
quietly capture program drop conv_ccode
program conv_ccode
args country_var
	kountry `country_var', from(other) stuck
	ren(_ISO3N_) (temp)
	kountry temp, from(iso3n) to(iso3c)
	drop temp
	ren (_ISO3C_) (iso3c)
end

// create a group of logged variables
quietly capture program drop create_logvars
program create_logvars
args vars

foreach i in `vars' {
    gen ln_`i' = ln(`i')
	loc lab: variable label `i'
	di "`lab'"
	label variable ln_`i' "Log `lab'"
}
end

// ================================================================

cd "$input"

foreach i in covid_response {
	global `i' "$input/`i'.xls"
	noisily capture erase "`i'.xls"
	noisily capture erase "`i'.txt"
}

// Regressions -------------------------------------------------------------

// Country-month regressions: ----------------------------------------------

// at the country-month-level, are there associations between lights and covid indicators?

use "$input/clean_validation_monthly_base.dta", clear

// reghdfe ln_sum_pix cornet* oxcgrt*, absorb(cat_iso3c cat_month) vce(cluster cat_iso3c)
// outreg2 using "covid_response.xls", append ///
// 		label dec(3) keep (cornet* oxcgrt*) ///
// 		bdec(3) addstat(Countries, e(N_clust), ///
// 		Adjusted Within R-squared, e(r2_a_within), ///
// 		Within R-squared, e(r2_within))

reghdfe g_an_ln_del_sum_pix_area cornet* oxcgrt*, absorb(cat_iso3c cat_month) vce(cluster cat_iso3c)

outreg2 using "covid_response.tex", append ///
	label dec(3) keep (`x') ///
	bdec(3) addstat(Countries, e(N_clust), ///
	Adjusted Within R-squared, e(r2_a_within), ///
	Within R-squared, e(r2_within))

outreg2 using "covid_response.xls", append ///
	label dec(3) keep (cornet* oxcgrt*) ///
	bdec(3) addstat(Countries, e(N_clust), ///
	Adjusted Within R-squared, e(r2_a_within), ///
	Within R-squared, e(r2_within))

foreach y in g_an_ln_del_sum_pix_area { //ln_sum_pix {
	foreach x of varlist cornet* oxcgrt* {
		reghdfe `y' `x', absorb(cat_iso3c cat_month) vce(cluster cat_iso3c)
		
		outreg2 using "covid_response.xls", append ///
		label dec(3) keep (`x') ///
		bdec(3) addstat(Countries, e(N_clust), ///
		Adjusted Within R-squared, e(r2_a_within), ///
		Within R-squared, e(r2_within))
		
		outreg2 using "covid_response.tex", append ///
		label dec(3) keep (`x') ///
		bdec(3) addstat(Countries, e(N_clust), ///
		Adjusted Within R-squared, e(r2_a_within), ///
		Within R-squared, e(r2_within))
		
// 		// -------------------------------------------------
// 		regress `y' `x' i.cat_iso3c##i.cat_month, robust
//		
// 		outreg2 using "covid_response.xls", append ///
// 		label dec(3) keep (`x' i.cat_month) ///
// 		bdec(3) 
	}
}

// Diff & Diff -------------------------------------------------------------

// Is there a drop in NTL after March at the ADM2 level?

cd "$input"

foreach i in covid_response2 {
	global `i' "$input/`i'.xls"
	noisily capture erase "`i'.xls"
	noisily capture erase "`i'.txt"
}

forval percentile = 0(20)80 { 
local percentile 73
use "$input/adm2_month_derived.dta", replace
keep ln_del_sum_pix_area g_an_ln_del_sum_pix_area after_march cat_objectid cat_yr cat_objectid
naomit
centile ln_del_sum_pix_area, centile(`percentile')
local perc `r(c_1)'
drop if cat_yr <= 3
drop if ln_del_sum_pix_area < `perc'

reghdfe g_an_ln_del_sum_pix_area c.after_march##i.cat_yr, absorb(cat_objectid) vce(cluster cat_objectid)
outreg2 using "covid_response2.tex", append ///
	label dec(3) keep (c.after_march##i.cat_yr) ///
	bdec(3) addstat("ADM2 Regions", e(N_clust), ///
	Adjusted Within R-squared, e(r2_a_within), ///
	Within R-squared, e(r2_within)) ///
	title("`percentile'")

}

// Table:
// Create table of differences at different *quantiles* of NTL

tempfile difftable
	clear
	set obs 1
	gen year = 0
	gen premar = 0
	gen postmar = 0
	gen dd = 0
save `difftable'

forval percentile = 0(20)80 { 
use "$input/adm2_month_derived.dta", replace
keep ln_del_sum_pix_area g_an_ln_del_sum_pix_area after_march cat_objectid cat_yr cat_objectid
naomit
centile ln_del_sum_pix_area, centile(`percentile')
local perc `r(c_1)'
drop if cat_yr <= 3
drop if ln_del_sum_pix_area < `perc'

collapse (mean) g_an_ln_del_sum_pix_area, by(cat_yr after_march)
reshape wide g_an_ln_del_sum_pix_area, i(cat_yr) j(after_march)
rename (g_an_ln_del_sum_pix_area0 g_an_ln_del_sum_pix_area1) (premar postmar)
gen dd = postmar - premar
decode cat_yr, gen(year)
destring year, replace
drop cat_yr
gen percentile = `percentile'

append using `difftable'
save `difftable', replace
}

clear
use `difftable'
sort percentile year




































