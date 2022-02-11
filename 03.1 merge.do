// Generate a random sample of the data (data is too big, so each iteration is too slow):
global sample = 1
if ($sample == 1) {
	clear
	input str70 datasets
	"NTL_VIIRS_appended_cleaned_all.dta"
	"all_dmsp.dta"
	"wb_pop_estimates_cleaned.dta"
	"covid_oxford_cleaned.dta"
	"covid_coronanet_cleaned.dta"
	"historical_wb_income_classifications.dta"
	"imf_pwt_GDP_annual.dta"
	"imf_oxf_GDP_quarter.dta"
	end
	levelsof datasets, local(datasets)

	foreach i in `datasets' {
	di "`i'"
	use "$input/`i'", clear
	keep if iso3c == "ZWE" | iso3c == "USA"
	save "$input/sample_`i'", replace
	}

	use "$input/sample_NTL_VIIRS_appended_cleaned_all.dta", clear
	capture quietly drop _merge
	mmerge iso3c year using "$input/sample_all_dmsp.dta"
	drop _merge
	mmerge iso3c year using "$input/sample_wb_pop_estimates_cleaned.dta"
	drop _merge
	mmerge iso3c year month using "$input/sample_covid_oxford_cleaned.dta"
	drop _merge
	mmerge iso3c year month using "$input/sample_covid_coronanet_cleaned.dta"
	drop _merge
	mmerge iso3c year using "$input/sample_historical_wb_income_classifications.dta"
	drop _merge
	mmerge iso3c year using "$input/sample_imf_pwt_GDP_annual.dta"
	drop _merge
	mmerge iso3c year quarter using "$input/sample_imf_oxf_GDP_quarter.dta"
	drop _merge
	mmerge objectid using "$raw_data/WorldPop/world_pop_2015_16.dta"
	drop _merge
	save "$input/sample_adm2_month_allvars.dta", replace
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Actual code for the full dataset:
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
mmerge 

save "$input/adm2_month_allvars.dta", replace


// CODE FOR FINAL 11/09/2021: (annual-country-level): -------------
clear
input str70 datasets
	"$input/all_dmsp.dta"
	"$input/wb_pop_estimates_cleaned.dta"
	"$input/historical_wb_income_classifications.dta"
	"$input/imf_pwt_GDP_annual.dta"
end
levelsof datasets, local(datasets)

use "$input/iso3c_year_viirs_new.dta", replace
foreach i in `datasets' {
	di "`i'"
	mmerge iso3c year using "`i'"
	drop _merge
}

keep if year >= 1992 & year <= 2020
drop country
save "$input/iso3c_year_base.dta", replace

















