use "C:\Users\user\Dropbox\CGD GlobalSat\HF_measures\input\iso3c_year_covid_viirs_new.dta", clear

gen del_sum_pix_area_new = del_sum_pix_new / del_sum_area_new
gen ln_del_sum_pix_area_new = ln(del_sum_pix_area_new)

label variable ln_del_sum_pix_area_new "Log VIIRS (clean) / area"

// first differences on the logged variables
foreach var of varlist ln_* {
	sort iso3c year
    generate g_`var' = `var' - `var'[_n-1] if iso3c==iso3c[_n-1]
	loc lab: variable label `var'
	di "`lab'"
	label variable g_`var' "Diff. `lab'"
}

br

keep iso3c year stringencyindex governmentresponseindex containmenthealthindex economicsupportindex restr_business restr_health_monitor restr_health_resource restr_mask restr_school restr_social_dist g_ln_del_sum_pix_area_new

foreach i in iso3c {
	di "`i'"
	encode `i', gen(cat_`i')
}

naomit

regress g_ln_del_sum_pix_area_new *index restr_*, robust

outreg2 using "$input/covid_response.tex", append label dec(3) bdec(3)

foreach y in g_ln_del_sum_pix_area_new { //ln_sum_pix {
	foreach x of varlist *index restr_* {
		regress `y' `x', robust
		
		outreg2 using "$input/covid_response.tex", append label dec(3) bdec(3)
	}
}



































