// alternatively, once can think of the synthetic GDP exercise as an 
// instrumental variable for the causal effect of GDP on night lights, with 
// exports, etc.

// regression estimates: --------------------------------------------------

loc count = 1

// loop through each of our dependent variables
foreach dv in ln_taxes_exc_soc ln_imports ln_exports ln_credit ln_elec {

// clear all regression estimates
est clear

// do the same regressions with and without country fixed effects
foreach fe in "Year and Country FE" "Country FE" {

if ("`fe'" == "Year and Country FE") {
    loc fe_insert "cat_iso3c cat_year"
}
else if ("`fe'" == "Country FE") {
    loc fe_insert "cat_iso3c"
}

use "$input/clean_synthetic_reg_prior.dta", clear
keep `dv' year ln_rgdp_lcu ln_del_sum_pix_area cat_iso3c cat_year
loc lab: variable label `dv'

// get rid of missing variables:
naomit

rename ln_del_sum_pix_area Y
rename ln_rgdp_lcu         X

// regression estimates: --------------------------------------------------

// OLS estimate of Lights on GDP
eststo: reghdfe Y X, absorb(`fe_insert') vce(cluster cat_iso3c)

// First Stage regression of GDP on IV
rename X X_temp
rename `dv' X
eststo: reghdfe X_temp X, absorb(`fe_insert') vce(cluster cat_iso3c)
rename X `dv'
rename X_temp X

// IV estimate using country and year fixed effects:
eststo: ivreghdfe Y (X=`dv'), absorb(`fe_insert') vce(cluster cat_iso3c)
}

// output
if (`count' == 1) {
	esttab using "$overleaf/gdp_iv.tex", replace f  ///
	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
	keep(X) coeflabel(X "`lab'") ///  
	label booktabs noobs nonotes  collabels(none) alignment(D{.}{.}{-1}) ///
	mtitles("Year and Country FE" "Country FE" "Year and Country FE" "Country FE" "Year and Country FE" "Country FE") mgroups("OLS" "First Stage" "2SLS", pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
}
else {
	esttab using "$overleaf/gdp_iv.tex", append f  ///
	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
	keep(X) coeflabel(X "`lab'") ///  
	label booktabs nodep nonum nomtitles nolines noobs nonotes collabels(none) alignment(D{.}{.}{-1})    
}

// add to our counter
local ++count
}



use "$input/clean_synthetic_reg_prior.dta", clear














