// first, get a dataset of country-level "night-lights-imputed" GDP. then, feed
// this into Dev's code to get the beta convergence graphs.

use "$input/iso3c_year_aggregation.dta", clear

// keep log BM, log DMSP, year, and country
keep ln_WDI_ppp_pc ln_sum_pix_bm_pc ln_sum_light_dmsp_pc year iso3c sum_area poptotal
order iso3c year
sort iso3c year

// merge with other indicators
mmerge iso3c year using "$input/clean_primary_yrs_ed.dta"
mmerge iso3c year using "$input/clean_vdem.dta"
mmerge iso3c year using "$input/khose_wb_gdp_deflator.dta"
mmerge iso3c year using "$input/clean_wd_wdi_lots_indicators.dta"
mmerge iso3c year using "$input/dmsp_predictions.dta"
drop _merge
check_dup_id "iso3c year"

// Oil-producers from IMF (http://datahelp.imf.org/knowledgebase/articles/516096-which-countries-comprise-export-earnings-fuel-a)
gen oil =	iso3c == "DZA" | ///
			iso3c == "AGO" | ///
			iso3c == "AZE" | ///
			iso3c == "BHR" | ///
			iso3c == "BRN" | ///
			iso3c == "TCD" | ///
			iso3c == "COG" | ///
			iso3c == "ECU" | ///
			iso3c == "GNQ" | ///
			iso3c == "GAB" | ///
			iso3c == "IRN" | ///
			iso3c == "IRQ" | ///
			iso3c == "KAZ" | ///
			iso3c == "KWT" | ///
			iso3c == "NGA" | ///
			iso3c == "OMN" | ///
			iso3c == "QAT" | ///
			iso3c == "RUS" | ///
			iso3c == "SAU" | ///
			iso3c == "TTO" | ///
			iso3c == "TKM" | ///
			iso3c == "ARE" | ///
			iso3c == "VEN" | ///
			iso3c == "YEM" | ///
			iso3c == "LBY" | ///
			iso3c == "TLS" | ///
			iso3c == "SDN"
label variable oil "Oil producing country"
			
// for terms of trade and inflation, we want growth numbers
fillin iso3c year
sort iso3c year
bys iso3c: gen tti2 = tti / tti[_n-1]

// fill some constant country-level variables in
bys iso3c: fillmissing regionname 
create_categ(iso3c year)

order iso3c year cat_iso3c cat_year
sort iso3c year cat_iso3c cat_year

// fix ntl data
gen ln_sum_pix_dmsp_pred_pc = log(sum_pix_dmsp_pred / poptotal)
gen ln_ntl = ln_sum_pix_bm_pc
replace ln_ntl = ln_sum_light_dmsp_pc if year == 1992
replace ln_sum_pix_dmsp_pred_pc = ln_sum_light_dmsp_pc if mi(ln_sum_pix_dmsp_pred_pc)

// generate growth
keep if year == 1992 | year ==2020
foreach i in ln_ntl ln_WDI_ppp_pc ln_sum_pix_dmsp_pred_pc {
	sort iso3c year
	bys iso3c: gen gr_`i' = `i'[_n+1] - `i'
}

keep if year == 1992
drop ln_sum_light_dmsp_pc ln_sum_pix_bm_pc ln_sum_pix_dmsp_pred_pc

// dropping some variables because they cause us to lose too many countries
mdesc
drop gov_ed_pct tti tti2 _fillin ln_ntl
check_dup_id "iso3c year"

// run regressions ----------------------------------------
// 1. reg Delta_NTL_2020_2012 ln_GDP_2012
// 2. reg Delta_ln_GDP_2020_2012 ln_GDP_2012 X_2012
// 3. reg Delta_NTL_2020_2012 ln_GDP_2012 X_2012

// variable labels:
label variable gr_ln_ntl "Log Growth Night Lights pc"
label variable gr_ln_WDI_ppp_pc "Log Growth GDP pc"
label variable gr_ln_sum_pix_dmsp_pred_pc "Log Growth Night Lights (Spliced) pc"
foreach v in pyrf pyrm v2x_rule dem def_a le urb_pop_pct oil_rent fert gov_cons_pct gov_milt_pct oil {
	local x: variable label `v'
	local nz = subinstr("`x'", "%", "\%", .)
	label variable `v' "`nz'"
}

loc j = 1
foreach Y in gr_ln_ntl gr_ln_WDI_ppp_pc gr_ln_sum_pix_dmsp_pred_pc {
	reg `Y' ln_WDI_ppp_pc
	eststo reg`j'
	loc j = `j' + 1
	reg `Y' ln_WDI_ppp_pc v2x_rule dem def_a le urb_pop_pct oil_rent fert gov_cons_pct gov_milt_pct oil
	eststo reg`j'
	loc j = `j' + 1
}

esttab reg1 reg2 reg3 reg4 reg5 reg6 using "$overleaf/barro_salai_martin_regressions.tex", replace f  ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01 **** 0.001) ///
label booktabs nobaselevels collabels(none) ///
sfmt(3)

