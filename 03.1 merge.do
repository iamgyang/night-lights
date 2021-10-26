use "$input/NTL_VIIRS_appended_cleaned_all.dta", clear
capture quietly drop _merge
mmerge iso3c year using "$input/all_dmsp.dta"
drop _merge
mmerge iso3c year using "$input/wb_pop_estimates_cleaned.dta"
drop _merge
mmerge iso3c year month using "$input/covid_oxford_cleaned.dta"
drop _merge
mmerge iso3c year month using "$input/covid_coronanet_cleaned.dta"
drop _merge
mmerge iso3c year using "$input/historical_wb_income_classifications.dta"
drop _merge
mmerge iso3c year using "$input/imf_pwt_GDP_annual.dta"
drop _merge
mmerge iso3c year quarter using "$input/imf_oxf_GDP_quarter.dta"
drop _merge
mmerge objectid using "$raw_data/WorldPop/world_pop_2015_16.dta"
drop _merge

// foreach i in iso3c year month {
//     assert !missing(`i')
// }
// check_dup_iso "objectid year month"

save "$input/adm2_month_allvars.dta", replace



