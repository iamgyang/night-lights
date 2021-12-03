cd "$input"

foreach i in full_hender overlaps_hender full_same_sample_hender ///
	full_gold overlaps_gold full_same_sample_gold {
	global `i' "$overleaf/`i'.tex"
	noisily capture erase "$overleaf/`i'.xls"
	noisily capture erase "$overleaf/`i'.txt"
	noisily capture erase "$overleaf/`i'.tex"
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

// Create a function that runs the regressions we want and outputs a table:
capture program drop gr_lev_reg
program gr_lev_reg
	
	////////////////////////////////////////////////////////////////////////////
	// 	parameters
	// output TEX file (outfile)
	// dependent variabls (dep_vars)
	// variables to be absorbed (abs_vars)
	// specify whether it's a growth or levels regression (growth levels)
	syntax, outfile(string) dep_vars(namelist) [abs_vars(namelist) growth levels]
	
	////////////////////////////////////////////////////////////////////////////
	eststo clear

	// create a local that contains the lights variable labels
	foreach i in `dep_vars' {
		loc lab: variable label `i'
		
		// Remove parts of the label for formatting purposes
		local lab = subinstr("`lab'", " pixels", "", .)
		local lab = subinstr("`lab'", "/area", "", .)
		local lab = subinstr("`lab'", " / area", "", .)
		local lab = subinstr("`lab'", "per capita", "", .)
		local lab = subinstr("`lab'", "Log ", "", .)
		local lab = subinstr("`lab'", "Growth in", "", .)
		local lab = subinstr("`lab'", "Mean", "", .)
		local lab = subinstr("`lab'", "Diff. ", "", .)
		local lab = subinstr("`lab'", "  ", " ", .)
		local lab = subinstr("`lab'", "  ", " ", .)
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
		
		if (inlist("`light_var'", "ln_del_sum_pix_area", "g_ln_del_sum_pix_pc", ///
		"g_ln_sum_pix_pc")) {
			local year 2012
		}
		else if (inlist("`light_var'", "lndn", "ln_sum_light_dmsp_div_area", ///
		"g_ln_sum_light_dmsp_pc", "mean_g_ln_lights_gold")) {
			local year 1992
		}
		
		// store the variable label of the light variable we're using in `lab'
		loc lab: variable label `light_var'
		
		// for formatting, we have to rename the variables into generic
		// names
		
		// GROWTH regressions
		if ("`growth'" != "" & "`levels'" == "") {
			preserve
			rename `light_var' log_lights_area_generic
			
			// For growth regressions, growth is defined as the average of the 
			// logged differences across each year, so we have to look at the variable 
			// of interest and collapse it.

			keep g_ln_WDI_ppp_pc cat_iso3c year log_lights_area_generic cat_wbdqcat_3
			naomit
			collapse (mean) g_ln_WDI_ppp_pc year log_lights_area_generic, by(cat_iso3c cat_wbdqcat_3)
			eststo: regress g_ln_WDI_ppp_pc log_lights_area_generic, vce(hc3)
			eststo: regress g_ln_WDI_ppp_pc c.log_lights_area_generic##i.cat_wbdqcat_3, vce(hc3)
			restore
			local label_prefix "Growth in "
			local label_suffix " per capita"
		}
		
		// LEVELS regressions
		// bare levels regression: country & year fixed effects
		else if ("`growth'" == "" & "`levels'" != "") {
			preserve
			rename `light_var' log_lights_area_generic
			eststo: reghdfe ln_WDI log_lights_area_generic, absorb(`abs_vars') ///
				vce(cluster cat_iso3c)
				estadd local NC `e(N_clust)'
				local y= round(`e(r2_a_within)', .001)
				estadd local WR2 `y'

			// levels regression with income interaction & income dummy (maintain country-year FE)
			eststo: reghdfe ln_WDI c.log_lights_area_generic##i.cat_wbdqcat_3, ///
				absorb(`abs_vars') vce(cluster cat_iso3c)
				estadd local NC `e(N_clust)'
				local y = round(`e(r2_a_within)', .001)
				estadd local WR2 `y'
			restore
		}
		else if ("`growth'" == "`levels'") {
		    _error("You must specify either a growth or a levels regression.")
		}
	}
	
	if ("`growth'" == "" & "`levels'" != "") {
	    local scalar_labels `"scalars("NC Number of Countries" "WR2 Adjusted Within R-squared")"'
	}
	
	// output
	gen log_lights_area_generic = .
	label variable log_lights_area_generic "`label_prefix'Log Lights/Area`label_suffix'"
	esttab using "`outfile'", replace f  ///
		b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
		label booktabs nomtitle nobaselevels collabels(none) ///
		`scalar_labels' ///
		sfmt(3) ///
		mgroups("`dep_var_labs'", pattern(1 0 1 0 1 0) ///
		prefix(\multicolumn{@span}{c}{) suffix(}) span ///
		erepeat(\cmidrule(lr){@span})) drop(*.cat_wbdqcat_3 _cons)
end

// TEST: ---------------------------------------------------------------

use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear
keep iso3c year ln_sum_light_dmsp_div_area ln_del_sum_pix_area
naomit
br
scatter(ln_sum_light_dmsp_div_area  ln_del_sum_pix_area)

// ---------------------------------------------------------------------
// LEVELS
// ---------------------------------------------------------------------

// full regression Henderson ------------------------------------

use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear
/*
From Henderson 2012:
"We exclude Bahrain and Singapore because they are outliers in terms of
having a large percentage of their pixels top-coded, Equatorial Guinea
because nearly all of its lights are from gas flares (see Section V below),
and Serbia and Montenegro because of changing borders."
*/
replace lndn = . if iso3c == "SGP"
replace lndn = . if iso3c == "GNQ"
replace lndn = . if iso3c == "BHR"
replace lndn = . if iso3c == "SRB"
replace lndn = . if iso3c == "MNE"

gr_lev_reg, levels outfile("$full_hender") ///
	dep_vars(lndn ln_sum_light_dmsp_div_area ln_del_sum_pix_area) abs_vars(cat_iso3c cat_year)

// // regression on overlaps Henderson ---------------------------
use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear
replace lndn = . if iso3c == "SGP"
replace lndn = . if iso3c == "GNQ"
replace lndn = . if iso3c == "BHR"
replace lndn = . if iso3c == "SRB"
replace lndn = . if iso3c == "MNE"

keep if year == 2012 | year == 2013
keep ln_sum_light_dmsp_div_area ln_del_sum_pix_area ln_WDI cat_wbdqcat_3 cat_iso3c iso3c year

// delete missing variables
naomit

save "$input/clean_validation_overlap.dta", replace

gr_lev_reg, levels outfile("$overlaps_hender") ///
	dep_vars(ln_sum_light_dmsp_div_area ln_del_sum_pix_area) abs_vars(cat_iso3c)

// full regression Henderson on same sample as overlapping -------------------

use "$input/clean_validation_overlap.dta", clear

/*
we need at least 2 observations per country to make country and time fixed 
effects, so drop those observations that don't have that
*/
bysort iso3c: gen n = _N
drop if n < 2

// store a local w/ the countries in the same sample as overlapping regressions.
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

gr_lev_reg, levels outfile("$full_same_sample_hender") ///
	dep_vars(lndn ln_sum_light_dmsp_div_area ln_del_sum_pix_area) ///
	abs_vars(cat_iso3c cat_year)

// --------------------------------------------------------------------------
// GROWTH
// --------------------------------------------------------------------------

// full regression Goldberg -------------------------------------------------
use "$input/sample_iso3c_year_pop_den__allvars2.dta", replace

gr_lev_reg, growth outfile("$full_gold") ///
	dep_vars(g_ln_sumoflights_gold_pc g_ln_sum_light_dmsp_pc g_ln_del_sum_pix_pc)

// regression on overlaps Goldberg -----------------------------------------
use "$input/sample_iso3c_year_pop_den__allvars2.dta", replace

keep if year == 2013
keep g_ln_del_sum_pix_pc g_ln_sum_light_dmsp_pc g_ln_WDI_ppp_pc ///
	cat_iso3c ln_WDI_ppp_pc_2012 cat_wbdqcat_3 year iso3c

// remove missing variables
naomit

save "$input/clean_validation_overlap_gold.dta", replace

// run regressions:
gr_lev_reg, growth outfile("$overlaps_gold") ///
	dep_vars(g_ln_sum_light_dmsp_pc g_ln_del_sum_pix_pc)

// full regression Goldberg on same sample as overlapping ------------------
use "$input/clean_validation_overlap_gold.dta", clear
levelsof iso3c, local(countries_in_overlap)

// restrict sample:
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

// run regressions
gr_lev_reg, growth outfile("$full_same_sample_gold") ///
	dep_vars(g_ln_sumoflights_gold_pc g_ln_sum_light_dmsp_pc g_ln_del_sum_pix_pc)

	


























