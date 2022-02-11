use "$input/brazil_subnatl_grp.dta", clear
append using "$input/global_subnational_data_clean_1.dta"
append using "$input/india_subnatl_grp.dta"
// note that all of these are in local currency units.
save "$input/global_subnational_data_clean_2.dta", replace
gen country = ""
replace country = "Australia" if iso3c == "AUS"
replace country = "India" if iso3c == "AUS"