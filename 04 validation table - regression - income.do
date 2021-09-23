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

// ================================================================
// HENDERSON ======================================================
// ================================================================

// full regression Henderson ------------------------------------
use clean_validation_base.dta, clear

capture program drop run_henderson_full_regression
program run_henderson_full_regression
	args outfile
	
	foreach light_var in lndn ln_sum_light_dmsp_div_area ln_del_sum_pix_area ln_sum_pix_area {
	foreach gdp_var in ln_WDI {
			// with income interaction & income dummy (maintain country-year FE)
			if (inlist("`light_var'", "ln_del_sum_pix_area", "ln_sum_pix_area")) {
					local year 2012
			}
			else if (inlist("`light_var'", "lndn", "ln_sum_light_dmsp_div_area")) {
					local year 1992
			}
			
			reghdfe `gdp_var' `light_var' c.`light_var'#i.cat_income`year', ///
				absorb(cat_iso3c cat_yr) vce(cluster cat_iso3c)
			outreg2 using "`outfile'", append ///
				label dec(3) ///
				bdec(3) addstat(Countries, e(N_clust), ///
				Adjusted Within R-squared, e(r2_a_within), ///
				Within R-squared, e(r2_within))
	}
	}
	end
	
run_henderson_full_regression "$full_hender"

// regression on overlaps Henderson ------------------------------------
use "clean_validation_base.dta", clear

keep if year == 2012 | year == 2013

keep ln_sum_light_dmsp_div_area ln_del_sum_pix_area ln_sum_pix_area ln_WDI cat_income2012 cat_iso3c iso3c

foreach var of varlist _all{
	drop if missing(`var')
}

save "clean_validation_overlap.dta", replace

foreach light_var in ln_sum_light_dmsp_div_area ln_del_sum_pix_area ln_sum_pix_area {
foreach gdp_var in ln_WDI {
		// with income interaction & income dummy (maintain country-year FE)
		di "`gdp_var' `light_var'"
		{
		reghdfe `gdp_var' `light_var' c.`light_var'#i.cat_income2012, ///
			absorb(cat_iso3c) vce(cluster cat_iso3c)
		outreg2 using "$overlaps_hender", append ///
			label dec(3) ///
			bdec(3) addstat(Countries, e(N_clust), ///
			Adjusted Within R-squared, e(r2_a_within), ///
			Within R-squared, e(r2_within))
		}
}
}

// ======================================================================
// Goldberg ============================================================
// ======================================================================

// full regression Goldberg ------------------------------------
use "clean_validation_base.dta", replace

capture program drop run_goldberg_full_regression
program run_goldberg_full_regression
	args out_file

	// define 2 datasets: 1 that is collapsed from 1992 - 2012; another collapsed from 2012-2021
	foreach year in 1992 2012 {
		preserve
		
		if `year' == 1992 {
			keep if year >=1992 & year<=2012
		}
		else if `year' == 2012 {
			keep if year >=2012
		}
		
		keep g_ln_gdp_gold g_ln_WDI_ppp_pc g_ln_del_sum_pix_pc g_ln_sum_pix_pc ///
		g_ln_sum_light_dmsp_pc ///
		mean_g_ln_lights_gold g_ln_gdp_gold g_ln_sumoflights_gold_pc ///
		cat_iso3c ln_WDI_ppp_pc_`year' ln_WDI_ppp_pc_`year' cat_income`year' year
		
		ds
		local varlist `r(varlist)'
		local excluded cat_iso3c cat_income`year'
		local varlist : list varlist - excluded 
		
// 		include "$root/HF_measures/code/copylabels.do"
		collapse (mean) `varlist', by(cat_iso3c cat_income`year')
// 		include "$root/HF_measures/code/attachlabels.do"
		save "angrist_goldberg_`year'.dta", replace
		restore	
	}
	
	// run regressions:
	foreach x_var in g_ln_del_sum_pix_pc g_ln_sum_pix_pc g_ln_sum_light_dmsp_pc ///
	mean_g_ln_lights_gold {
		if (inlist("`x_var'", "g_ln_del_sum_pix_pc", "g_ln_sum_pix_pc")) {
			local year 2012
		}
		else if (inlist("`x_var'", "g_ln_sum_light_dmsp_pc", "mean_g_ln_lights_gold")) {
			local year 1992
		}
		use angrist_goldberg_`year'.dta, clear
		foreach y_var in g_ln_WDI_ppp_pc {
			regress `y_var' `x_var', robust
			outreg2 using "`out_file'", append label dec(4)
			
			regress `y_var' `x_var' i.cat_income`year' ///
				c.`x_var'##i.cat_income`year', robust
			outreg2 using "`out_file'", append label dec(4)
		}
	}
end

run_goldberg_full_regression "$full_gold"


// regression on overlaps Goldberg ------------------------------------
use "clean_validation_base.dta", replace

keep if year == 2013
keep g_ln_del_sum_pix_pc g_ln_sum_pix_pc g_ln_sum_light_dmsp_pc g_ln_WDI_ppp_pc ///
cat_iso3c ln_WDI_ppp_pc_2012 cat_income2012 cat_income1992 year iso3c

ds, has(type numeric)
foreach var of varlist `r(varlist)' {
	drop if `var' == .
}
save "clean_validation_overlap_gold.dta", replace

// run regressions:
foreach x_var in g_ln_del_sum_pix_pc g_ln_sum_pix_pc g_ln_sum_light_dmsp_pc {
foreach y_var in g_ln_WDI_ppp_pc {
	capture regress `y_var' `x_var', robust
	capture outreg2 using "$overlaps_gold", append label dec(4)
	
	capture regress `y_var' `x_var' i.cat_income2012 ///
	c.`x_var'##i.cat_income2012, robust
	capture outreg2 using "$overlaps_gold", append label dec(4)
}
}










