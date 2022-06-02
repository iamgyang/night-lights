global datasets pwt mad wdi bm dmsp

// first, get a dataset of country-level "night-lights-imputed" GDP. then, feed
// this into Dev's code to get the beta convergence graphs.

use "$input/iso3c_year_aggregation.dta", clear

// black marble December 
keep ln_WDI_ppp ln_sum_pix_bm_dec_area ln_sum_light_dmsp_div_area cat_iso3c cat_year year iso3c
reghdfe ln_WDI_ppp ln_sum_pix_bm_dec_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
predict ln_gdp_bm

// DMSP
reghdfe ln_WDI_ppp ln_sum_light_dmsp_div_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
predict ln_gdp_dmsp

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

