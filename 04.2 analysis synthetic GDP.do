// Create Synthetic GDP ---------------------------------------------------

local use_taxes "no"

use "$input/clean_merged_synth.dta", clear

replace deflator = deflator / 100
assert deflator < 20 | missing(deflator) | iso3c == "ZWE"

// credit is a percentage of GDP, so convert it to an actual number:
replace credit = credit * rgdp_lcu / 100

// electricity should be population multiplied by per capita measure:
gen elec = elec_pc * poptotal

// taxes should be deflated as they're in local currency units:
replace taxes_exc_soc = taxes_exc_soc / deflator

keep iso3c year taxes_exc_soc imports exports credit rgdp_lcu elec
label variable taxes_exc_soc "Gen govt tax revenue (constant LCU)"
label variable imports "Imports (constant USD)"
label variable exports "Exports (constant USD)"
label variable credit "Total credit to private sector (constant LCU)"
label variable rgdp_lcu "Real GDP (LCU)"
label variable elec "Electricity consumption (kWh)"

// logged variables:
create_logvars "taxes_exc_soc imports exports credit rgdp_lcu elec"

// merge with lights
mmerge iso3c year using "$input/sample_iso3c_year_pop_den__allvars2.dta"
keep if _merge == 3

loc dep_vars ln_taxes_exc_soc ln_imports ln_exports ln_credit ln_elec

save "$input/clean_synthetic_reg_prior.dta", replace

est clear
use "$input/clean_synthetic_reg_prior.dta", clear
keep `dep_vars' year ln_rgdp_lcu ln_del_sum_pix_area cat_iso3c cat_year
loc lab "All"

// get rid of missing variables:
naomit

// regression estimates: 
reg ln_rgdp_lcu `dep_vars' if year <= 2012
predict yhat if year > 2012, xb

// lights on GDP
eststo: reghdfe ln_rgdp_lcu ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
	estadd local NC `e(N_clust)'
	local y = round(`e(r2_a_within)', .001)
	estadd local WR2 `y'

// regress on NTL:
keep if !missing(yhat)


// clear prior TEX regression estimates
foreach i in synthetic_gdp {
	noisily capture erase "$overleaf/`i'.xls"
	noisily capture erase "$overleaf/`i'.txt"
	noisily capture erase "$overleaf/`i'.tex"
}

// output regressions
eststo: reghdfe yhat ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
	estadd local NC `e(N_clust)'
	local y = round(`e(r2_a_within)', .001)
	estadd local WR2 `y'
esttab using "$overleaf/synthetic_gdp.tex", replace f  ///
	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
	keep(ln_del_sum_pix_area) coeflabel(ln_del_sum_pix_area "All Variables") ///  
	label booktabs noobs nonotes  collabels(none) alignment(D{.}{.}{-1}) ///
	mtitles("Log GDP (2013-2019/20)" "Predicted Log GDP (2013-2019/20)")

/*
because we have so many missing variables for each of the measures above, 
create a synthetic GDP for EACH variable and run a regression. 
*/
foreach dv in `dep_vars' {
est clear
use "$input/clean_synthetic_reg_prior.dta", clear
keep `dv' year ln_rgdp_lcu ln_del_sum_pix_area cat_iso3c cat_year
loc lab: variable label `dv'
// get rid of missing variables:

naomit

// regression estimates: --------------------------------------------------

reg ln_rgdp_lcu `dv' if year <= 2012
predict yhat if year > 2012, xb

// lights on GDP
eststo: reghdfe ln_rgdp_lcu ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
	estadd local NC `e(N_clust)'
	local y = round(`e(r2_a_within)', .001)
	estadd local WR2 `y'

// regress on NTL:
keep if !missing(yhat)

eststo: reghdfe yhat ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
	estadd local NC `e(N_clust)'
	local y = round(`e(r2_a_within)', .001)
	estadd local WR2 `y'

// output
esttab using "$overleaf/synthetic_gdp.tex", append f  ///
	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
	keep(ln_del_sum_pix_area) coeflabel(ln_del_sum_pix_area "`lab'") ///  
	label booktabs nodep nonum nomtitles nolines noobs nonotes collabels(none) alignment(D{.}{.}{-1})
}




