/*
https://www.youtube.com/watch?v=L0aLsZFw28k
 */

// ================================================================

cd "$input"

foreach i in full_hender overlaps_hender full_same_sample_hender ///
	full_gold overlaps_gold full_same_sample_gold {
	global `i' "C:/Users/gyang/Dropbox/Apps/Overleaf/Night Lights/`i'.tex"
	noisily capture erase "C:/Users/gyang/Dropbox/Apps/Overleaf/Night Lights/`i'.xls"
	noisily capture erase "C:/Users/gyang/Dropbox/Apps/Overleaf/Night Lights/`i'.txt"
	noisily capture erase "C:/Users/gyang/Dropbox/Apps/Overleaf/Night Lights/`i'.tex"
}

// ------------------------------------------------------------------------
// Confirming that we have the same dataset with the original Henderson variables:

use "$raw_data/HWS AER replication/hsw_final_tables_replication/global_total_dn_uncal.dta", clear
keep year iso3v10 lndn lngdpwdilocal
drop if lndn == . | lngdpwdilocal == . 
rename (lndn lngdpwdilocal iso3v10) (lndn_orig lngdpwdilocal_orig iso3c)
tempfile original_hender
save `original_hender'

use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear
keep lndn lngdpwdilocal iso3c year
drop if lndn == . | lngdpwdilocal == . 
mmerge iso3c year using `original_hender'

assert lndn == lndn_orig 
assert lngdpwdilocal == lngdpwdilocal_orig

save "$input/vars_hender.dta", replace

// ---------------------------------------------------------------------
// HENDERSON 
// ---------------------------------------------------------------------

// full regression Henderson ------------------------------------
use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear

capture program drop run_henderson_full_regression
program run_henderson_full_regression
	args outfile dep_vars abs_vars
	eststo clear

	// create a local that contains the lights variable labels
	foreach i in `dep_vars' {
		loc lab: variable label `i'
		local macrolen: length local dep_var_labs

		// get the start and end year
		preserve
		keep `i' year
		naomit
		keep year
		duplicates drop 
		summarize year
		restore

		/*
		If the macro has stuff in it, then append the new string to the end
		of the macro. Otherwise, create the macro.
		*/
		if (`macrolen'>0) {
			local dep_var_labs "`dep_var_labs'" "\shortstack{`lab'\\(`r(min)' - `r(max)')}"
		} 
		else if (`macrolen'==0) {
			local dep_var_labs "\shortstack{`lab'\\(`r(min)' - `r(max)')}"
		}
	}

	// loop through night lights variables to do the regressions
	foreach light_var in `dep_vars' {
		preserve
		// store the variable label of the light variable we're using
		loc lab: variable label `light_var'
		// for formatting, we have to rename the variables into generic
		// names
		rename `light_var' log_lights_area_generic
		label variable log_lights_area_generic "Log Lights Area"

		// bare henderson regression: country & year fixed effects
		eststo: reghdfe ln_WDI log_lights_area_generic, absorb(`abs_vars') vce(cluster cat_iso3c)
		estadd local NC `e(N_clust)'
		local y= round(`e(r2_a_within)', .001)
		estadd local WR2 `y'

		// with income interaction & income dummy (maintain country-year FE)
		if (inlist("`light_var'", "ln_del_sum_pix_area", "g_ln_del_sum_pix_pc", "g_ln_sum_pix_pc")) {
			local year 2012
		}
		else if (inlist("`light_var'", "lndn", "ln_sum_light_dmsp_div_area", "g_ln_sum_light_dmsp_pc", "mean_g_ln_lights_gold")) {
			local year 1992
		}

		// henderson regression: with income interaction (fixed intercept)
		eststo: reghdfe ln_WDI log_lights_area_generic c.log_lights_area_generic#i.cat_wbdqcat_3, ///
			absorb(`abs_vars') vce(cluster cat_iso3c)
		estadd local NC `e(N_clust)'
		local y = round(`e(r2_a_within)', .001)
		estadd local WR2 `y'
		restore
	}
	gen log_lights_area_generic = 0
	label variable log_lights_area_generic "Log Lights/Area"

	// output
	esttab using "`outfile'", replace f  ///
		b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
		label booktabs nomtitle collabels(none) nobaselevels ///
		scalars("NC Number of Countries" "WR2 Adjusted Within R-squared") sfmt(3) ///
		mgroups("`dep_var_labs'", pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	drop log_lights_area_generic
end

run_henderson_full_regression "$full_hender" "lndn ln_sum_light_dmsp_div_area ln_del_sum_pix_area" "cat_iso3c cat_year"

// // regression on overlaps Henderson ------------------------------------
use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear

keep if year == 2012 | year == 2013

keep ln_sum_light_dmsp_div_area ln_del_sum_pix_area ln_WDI cat_wbdqcat_3 cat_iso3c iso3c year

naomit

save "$input/clean_validation_overlap.dta", replace

run_henderson_full_regression "$overlaps_hender" "ln_sum_light_dmsp_div_area ln_del_sum_pix_area" "cat_iso3c"

// full regression Henderson on same sample as overlapping ------------------------------------

use "$input/clean_validation_overlap.dta", clear
levelsof iso3c, local(countries_in_overlap)

use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear
gen tokeep = "no"
foreach country_code in `countries_in_overlap' {
	replace tokeep = "yes" if iso3c == "`country_code'"
}
keep if tokeep == "yes"

// check that we have the same number of countries
local length_before: length local countries_in_overlap
levelsof iso3c, local(countries_in_overlap_after)
local length_after: length local countries_in_overlap_after
assert `length_after' == `length_before'

drop tokeep

run_henderson_full_regression "$full_same_sample_hender" "lndn ln_sum_light_dmsp_div_area ln_del_sum_pix_area" "cat_iso3c cat_year"

// ---------------------------------------------------------------------
// Goldberg 
// ---------------------------------------------------------------------

// full regression Goldberg ------------------------------------
use "$input/sample_iso3c_year_pop_den__allvars2.dta", replace

capture program drop run_goldberg_full_regression
program run_goldberg_full_regression
	args out_file dep_vars
	local dep_vars g_ln_del_sum_pix_pc g_ln_sum_light_dmsp_pc mean_g_ln_lights_gold
	esto clear
	// define 2 datasets: 1 that is collapsed from 1992 - 2012; another collapsed from 2012-2021
	foreach year in 1992 2012 {
		preserve

		if `year' == 1992 {
			keep if year >=1992 & year<=2012
		}
		else if `year' == 2012 {
			keep if year >=2012
		}

		keep g_ln_gdp_gold g_ln_WDI_ppp_pc g_ln_del_sum_pix_pc ///
			g_ln_sum_light_dmsp_pc ///
			mean_g_ln_lights_gold g_ln_gdp_gold g_ln_sumoflights_gold_pc ///
			cat_iso3c ln_WDI_ppp_pc_`year' ln_WDI_ppp_pc_`year' cat_wbdqcat_3 year

		ds
		local varlist `r(varlist)'
		local excluded cat_iso3c cat_wbdqcat_3
		local varlist : list varlist - excluded 

		// 		include "$root/HF_measures/code/copylabels.do"
		collapse (mean) `varlist', by(cat_iso3c cat_wbdqcat_3)
		// 		include "$root/HF_measures/code/attachlabels.do"
		save "$input/angrist_goldberg_`year'.dta", replace
		restore	
	}

	// create a local that contains the lights variable labels
	foreach i in `dep_vars' {
		loc lab: variable label `i'
		local macrolen: length local dep_var_labs

		// get the start and end year
		preserve
		keep `i' year
		naomit
		keep year
		duplicates drop 
		summarize year
		restore

/*
		If the macro has stuff in it, then append the new string to the end
		of the macro. Otherwise, create the macro.
*/
		if (`macrolen'>0) {
			local dep_var_labs "`dep_var_labs'" "\shortstack{`lab'\\(`r(min)' - `r(max)')}"
		} 
		else if (`macrolen'==0) {
			local dep_var_labs "\shortstack{`lab'\\(`r(min)' - `r(max)')}"
		}
	}

	// run regressions:
	foreach x_var in `dep_vars' {
		if (inlist("`x_var'", "g_ln_del_sum_pix_pc", "g_ln_sum_pix_pc")) {
			local year 2012
		}
		else if (inlist("`x_var'", "g_ln_sum_light_dmsp_pc", "mean_g_ln_lights_gold")) {
			local year 1992
		}
		use angrist_goldberg_`year'.dta, clear
		rename `x_var' x_var

		foreach y_var in g_ln_WDI_ppp_pc {
			rename `y_var' y_var

			eststo: regress y_var x_var, vce(hc3)
			eststo: regress y_var x_var i.cat_wbdqcat_3 ///
				c.x_var##i.cat_wbdqcat_3, vce(hc3)
		}
	}

	gen x_var = 0
	label variable x_var "Growth in Log Lights/Area"
	gen y_var = 0
	label variable y_var "Growth in GDP, PPP"

	// output
	esttab using "`outfile'", replace f  ///
		b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
		label booktabs nomtitle collabels(none) nobaselevels ///
		sfmt(3) ///
		mgroups("`dep_var_labs'", pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	drop x_var
	drop y_var

end

run_goldberg_full_regression "$full_gold"


// // regression on overlaps Goldberg ------------------------------------
// use "$input/sample_iso3c_year_pop_den__allvars2.dta", replace
//
// keep if year == 2013
// keep g_ln_del_sum_pix_pc g_ln_sum_light_dmsp_pc g_ln_WDI_ppp_pc ///
	// cat_iso3c ln_WDI_ppp_pc_2012 cat_wbdqcat_3 year iso3c
//
// ds, has(type numeric)
// foreach var of varlist `r(varlist)' {
// 	drop if `var' == .
// }
// save "$input/clean_validation_overlap_gold.dta", replace
//
// // run regressions:
// foreach x_var in g_ln_del_sum_pix_pc g_ln_sum_light_dmsp_pc {
// foreach y_var in g_ln_WDI_ppp_pc {
// 	capture regress `y_var' `x_var', robust
// 	capture outreg2 using "$overlaps_gold", append label dec(4)
//	
// 	capture regress `y_var' `x_var' i.cat_wbdqcat_3 ///
	// 	c.`x_var'##i.cat_wbdqcat_3, robust
// 	capture outreg2 using "$overlaps_gold", append label dec(4)
// }
// }
//
// // full regression Goldberg on same sample as overlapping ------------------------------------
// use "$input/clean_validation_overlap_gold.dta", clear
// levelsof iso3c, local(countries_in_overlap)
//
// // restrict sample:
// use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear
// gen tokeep = "no"
// foreach country_code in `countries_in_overlap' {
// 	replace tokeep = "yes" if iso3c == "`country_code'"
// }
// keep if tokeep == "yes"
//
// // check that we have the same number of countries
// local length_before: length local countries_in_overlap
// levelsof iso3c, local(countries_in_overlap_after)
// local length_after: length local countries_in_overlap_after
// assert `length_after' == `length_before'
//
// drop tokeep
//
// // run regressions
// run_goldberg_full_regression "$full_same_sample_gold"
//
//



////////////
	// seeout using "C:/Users/gyang/Dropbox/CGD GlobalSat//HF_measures/input/full_hender.txt"





