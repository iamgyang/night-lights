// ======================================================================
// HENDERSON ============================================================
// ======================================================================

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










