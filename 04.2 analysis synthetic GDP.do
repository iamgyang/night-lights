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
label variable taxes_exc_soc "Gen govt tax revenue" // (constant LCU)
label variable imports "Imports" //(constant USD)
label variable exports "Exports" //(constant USD)
label variable credit "Credit to private sector" //(constant LCU)
label variable rgdp_lcu "GDP" //(real, LCU)
label variable elec "Electricity consumption" //(kWh)

// logged variables:
create_logvars "taxes_exc_soc imports exports credit rgdp_lcu elec"

// merge with lights
mmerge iso3c year using "$input/sample_iso3c_year_pop_den__allvars2.dta"
keep if _merge == 3

loc dep_vars ln_taxes_exc_soc ln_imports ln_exports ln_credit ln_elec

save "$input/clean_synthetic_reg_prior.dta", replace

// for each year from 2013 - 2018, do a cross validation exercise where we 
// use the pre-cutoff year to fit the regression, and use the post-cutoff year to 
// predict GDP. make a graph of actual vs. predicted for each of those years, 
// as well as a simple regression table.
// ---------------------------------------------------------------------

est clear
foreach num of numlist 2012/2018 {

use "$input/clean_synthetic_reg_prior.dta", clear
keep ln_imports ln_exports ln_credit ln_elec ///
ln_rgdp_lcu ln_del_sum_pix_area ///
iso3c cat_iso3c cat_year year

// get rid of missing variables:
foreach var in ln_imports ln_exports ln_credit ln_elec ///
ln_rgdp_lcu {
drop if missing(`var')
}

// regression estimates: 
eststo: reg ln_rgdp_lcu ln_imports ln_exports ln_credit ln_elec if year <= `num'
estadd local OECD "No"
predict yhat, xb

// lights on GDP
eststo: reghdfe ln_rgdp_lcu ln_del_sum_pix_area if year > `num', absorb(cat_iso3c cat_year) vce(cluster cat_iso3c) 
	estadd local NC `e(N_clust)'
	local y = round(`e(r2_a_within)', .001)
	estadd local WR2 `y'
	estadd local OECD "No"
	

// actual vs. predicted graph -------

// cutoff categorical variable
gen pre_cutoff = "pre" if year <= `num'
replace pre_cutoff = "post" if year > `num'
label define cutoff 1 "pre" 2 "post"
encode pre_cutoff, generate(cutoff) label(cutoff)
drop pre_cutoff

// graph of actual vs. predicted
sepscatter ln_rgdp_lcu yhat, mc(blue black) ms(Oh + ) separate(cutoff) legend(position(0) bplacement(nwest) region(lwidth(none))) //title("Cutoff set at `num'")
gr export "$overleaf/scatter_actual_predicted_`num'.pdf", replace

// Same regressions on OECD countries
drop yhat
keep if iso3c == "AUS" |iso3c == "AUT" |iso3c == "BEL" |iso3c == "CAN" |iso3c == "CHL" |iso3c == "COL" |iso3c == "CRI" |iso3c == "CZE" |iso3c == "DNK" |iso3c == "EST" |iso3c == "FIN" |iso3c == "FRA" |iso3c == "DEU" |iso3c == "GRC" |iso3c == "HUN" |iso3c == "ISL" |iso3c == "IRL" |iso3c == "ISR" |iso3c == "ITA" |iso3c == "JPN" |iso3c == "KOR" |iso3c == "LVA" |iso3c == "LTU" |iso3c == "LUX" |iso3c == "MEX" |iso3c == "NLD" |iso3c == "NZL" |iso3c == "NOR" |iso3c == "POL" |iso3c == "PRT" |iso3c == "SVK" |iso3c == "SVN" |iso3c == "ESP" |iso3c == "SWE" |iso3c == "CHE" |iso3c == "TUR" |iso3c == "GBR" |iso3c == "USA"
eststo: reg ln_rgdp_lcu ln_imports ln_exports ln_credit ln_elec if year <= `num'
estadd local OECD "Yes"
predict yhat, xb

// lights on GDP
eststo: reghdfe ln_rgdp_lcu ln_del_sum_pix_area if year > `num', absorb(cat_iso3c cat_year) vce(cluster cat_iso3c) 
	estadd local NC `e(N_clust)'
	local y = round(`e(r2_a_within)', .001)
	estadd local WR2 `y'
	estadd local OECD "Yes"
}

esttab using "$overleaf/synthetic_gdp2.tex", replace f  ///
b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
booktabs collabels(none) mgroups("2012" "2013" "2014" "2015" "2016" "2017" "2018", pattern(1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) scalars("OECD OECD Countries Only?")


// // ---------------------------------------------------------------------
// // old synthetic GDP regressions
// est clear
// use "$input/clean_synthetic_reg_prior.dta", clear
// keep `dep_vars' year ln_rgdp_lcu ln_del_sum_pix_area cat_iso3c cat_year
// loc lab "All"
//
// // get rid of missing variables:
// naomit
//
// // regression estimates: 
// reg ln_rgdp_lcu `dep_vars' if year <= 2012
// predict yhat if year > 2012, xb
//
// // lights on GDP
// eststo: reghdfe ln_rgdp_lcu ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
// 	estadd local NC `e(N_clust)'
// 	local y = round(`e(r2_a_within)', .001)
// 	estadd local WR2 `y'
//
// // regress on NTL:
// keep if !missing(yhat)
//
// // clear prior TEX regression estimates
// foreach i in synthetic_gdp {
// 	noisily capture erase "$overleaf/`i'.xls"
// 	noisily capture erase "$overleaf/`i'.txt"
// 	noisily capture erase "$overleaf/`i'.tex"
// }
//
// // output regressions
// eststo: reghdfe yhat ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
// 	estadd local NC `e(N_clust)'
// 	local y = round(`e(r2_a_within)', .001)
// 	estadd local WR2 `y'
// esttab using "$overleaf/synthetic_gdp.tex", replace f  ///
// 	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
// 	keep(ln_del_sum_pix_area) coeflabel(ln_del_sum_pix_area "All Variables") ///  
// 	label booktabs noobs nonotes  collabels(none) alignment(D{.}{.}{-1}) ///
// 	mtitles("Log GDP (2013-2019/20)" "Predicted Log GDP (2013-2019/20)")
//
// /*
// because we have so many missing variables for each of the measures above, 
// create a synthetic GDP for EACH variable and run a regression. 
// */
// foreach dv in `dep_vars' {
// est clear
// use "$input/clean_synthetic_reg_prior.dta", clear
// keep `dv' year ln_rgdp_lcu ln_del_sum_pix_area cat_iso3c cat_year
// loc lab: variable label `dv'
// // get rid of missing variables:
//
// naomit
//
// // regression estimates: --------------------------------------------------
//
// reg ln_rgdp_lcu `dv' if year <= 2012
// predict yhat if year > 2012, xb
//
// // lights on GDP
// eststo: reghdfe ln_rgdp_lcu ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
// 	estadd local NC `e(N_clust)'
// 	local y = round(`e(r2_a_within)', .001)
// 	estadd local WR2 `y'
//
// // regress on NTL:
// keep if !missing(yhat)
//
// eststo: reghdfe yhat ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
// 	estadd local NC `e(N_clust)'
// 	local y = round(`e(r2_a_within)', .001)
// 	estadd local WR2 `y'
//
// // output
// esttab using "$overleaf/synthetic_gdp.tex", append f  ///
// 	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
// 	keep(ln_del_sum_pix_area) coeflabel(ln_del_sum_pix_area "`lab'") ///  
// 	label booktabs nodep nonum nomtitles nolines noobs nonotes collabels(none) alignment(D{.}{.}{-1})
// }
//
//
//
//
//
//
//
//
//
