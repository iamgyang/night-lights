// first, get a dataset of country-level "night-lights-imputed" GDP. then, feed
// this into Dev's code to get the beta convergence graphs.

use "$input/iso3c_year_aggregation.dta", clear

// keep log BM, log DMSP, year, and country
keep ln_WDI_ppp ln_sum_pix_bm_area ln_sum_light_dmsp_div_area year iso3c
order iso3c year
sort iso3c year

// merge with other indicators
mmerge iso3c year using "$input/clean_primary_yrs_ed.dta"
mmerge iso3c year using "$input/clean_vdem.dta"
mmerge iso3c year using "$input/khose_wb_gdp_deflator.dta"
mmerge iso3c year using "$input/clean_wd_wdi_lots_indicators.dta"
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

// run regressions
// 1. reg Delta_NTL_2020_2012 ln_GDP_2012
// 2. reg Delta_ln_GDP_2020_2012 ln_GDP_2012 X_2012
// 3. reg Delta_NTL_2020_2012 ln_GDP_2012 X_2012

// 1. reg Delta_NTL_2020_2012 ln_GDP_2012
keep if year == 1992 | year ==2020
gen ln_ntl = ln_sum_pix_bm_area
replace ln_ntl = ln_sum_light_dmsp_div_area if year == 1992
foreach i in ln_ntl ln_WDI_ppp {
	sort iso3c year
	bys iso3c: gen gr_`i' = `i'[_n+1] - `i'
}

keep if year == 1992
drop ln_sum_light_dmsp_div_area ln_sum_pix_bm_area

// dropping some variables because they cause us to lose too many countries
mdesc
drop gov_ed_pct tti tti2 _fillin ln_ntl
naomit
check_dup_id "iso3c year"

// run regressions

// 1. reg Delta_NTL_2020_2012 ln_GDP_2012
reg gr_ln_ntl ln_WDI_ppp
eststo reg1

// 2. reg Delta_ln_GDP_2020_2012 ln_GDP_2012 X_2012
reg gr_ln_WDI_ppp ln_WDI_ppp pyrf pyrm v2x_rule dem def_a le urb_pop_pct oil_rent fert gov_cons_pct gov_milt_pct inflation oil
eststo reg2

// 3. reg Delta_NTL_2020_2012 ln_GDP_2012 X_2012
reg gr_ln_ntl ln_WDI_ppp pyrf pyrm v2x_rule dem def_a le urb_pop_pct oil_rent fert gov_cons_pct gov_milt_pct inflation oil
eststo reg3

esttab reg1 reg2 reg3 using "$overleaf/barro_salai_martin_regressions.tex", replace f  ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01 **** 0.001) ///
label booktabs nobaselevels collabels(none) ///
sfmt(3)

