use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear
keep if year == 2013 | year == 2020
keep iso3c year cat_income2012 ln_WDI_ppp_pc ln_WDI ln_del_sum_pix_area
naomit
sort iso3c year

// logged variables
loc gdp_var ln_WDI ln_WDI_ppp_pc
loc light_var ln_del_sum_pix_area
foreach i in `gdp_var' `light_var' {
	bys iso3c: gen lg_`i' = `i'[_n+1] - `i'
	loc lab: variable label `i'
	label variable lg_`i' "Long Difference `lab'"
}
naomit

gen income = ""
replace income = "LIC" if cat_income2012 == 1
replace income = "LMIC" if cat_income2012 == 2
replace income = "UMIC" if cat_income2012 == 3
replace income = "HIC" if cat_income2012 == 4

save "$input/long_diff_concavity_dataset.dta", replace

// regress long diff log GDP ~ long diff log lights + log lights 2012 : long diff log lights
est clear
eststo: reg lg_ln_WDI lg_ln_del_sum_pix_area c.lg_ln_del_sum_pix_area#c.ln_del_sum_pix_area, vce(hc3)
eststo: reg lg_ln_WDI lg_ln_del_sum_pix_area i.cat_income2012#c.ln_del_sum_pix_area, vce(hc3)
esttab using "$overleaf/concavity.tex", replace f  ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
label booktabs nobaselevels collabels(none) ///
sfmt(3)



