// Create Synthetic GDP ---------------------------------------------------

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
label variable taxes_exc_soc "General government revenue from taxes, excluding social contributions (constant LCU)"
label variable imports "Imports (constant '15 USD)"
label variable exports "Exports (constant '15 USD)"
label variable credit "Total credit to private sector (constant LCU)"
label variable rgdp_lcu "Real GDP (LCU)"
label variable elec "Electricity consumption (kWh)"

// logged variables:
create_logvars "taxes_exc_soc imports exports credit rgdp_lcu elec"

// get rid of missing variables:
naomit

*******// Merge w/ Night Lights
// NOTE THAT THIS FILE IS CREATED LATER
mmerge iso3c year using "$input/sample_iso3c_year_pop_den__allvars2.dta"
keep if _merge == 3

// regression estimates:
reg ln_rgdp_lcu ln_taxes_exc_soc ln_imports ln_exports ln_credit ln_elec if year <= 2012
predict yhat if year > 2012, xb

foreach i in covid_synthetic {
	noisily capture erase "$output/`i'.xls"
	noisily capture erase "$output/`i'.txt"
	noisily capture erase "$output/`i'.tex"
}

// lights on GDP
reghdfe ln_rgdp_lcu ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
outreg2 using "$output/covid_synthetic.tex", append ///
	label dec(3) keep (ln_del_sum_pix_area) ///
	bdec(3) addstat(Countries, e(N_clust), ///
	Adjusted Within R-squared, e(r2_a_within), ///
	Within R-squared, e(r2_within))

// regress on NTL:
keep if !missing(yhat)

reghdfe yhat ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
outreg2 using "$output/covid_synthetic.tex", append ///
	label dec(3) keep (ln_del_sum_pix_area) ///
	bdec(3) addstat(Countries, e(N_clust), ///
	Adjusted Within R-squared, e(r2_a_within), ///
	Within R-squared, e(r2_within))





















