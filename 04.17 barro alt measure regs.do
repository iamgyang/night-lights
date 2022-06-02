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
			
// for terms of trade and inflation, we want growth numbers
sort iso3c year
bys iso3c: gen inflation2 = inflation / inflation[_n-1]
sort iso3c year
bys iso3c: gen tti2 = tti / tti[_n-1]


			
// fill some constant country-level variables in
drop _fillin
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
gen Y = ln_sum_pix_bm_area
replace Y = ln_sum_light_dmsp_div_area if year == 1992
sort iso3c year
bys iso3c: gen Y2 = Y[_n+1] - Y
drop if mi(Y2)
keep if year == 1992
drop ln_sum_light_dmsp_div_area ln_sum_pix_bm_area




















