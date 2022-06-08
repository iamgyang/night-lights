// Merge at an annual country level ----------------------------
clear
input str70 datasets
	"$input/all_dmsp.dta"
	"$input/wb_pop_estimates_cleaned.dta"
	"$input/historical_wb_income_classifications.dta"
	"$input/imf_pwt_GDP_annual.dta"
	"$input/bm_iso3c_year.dta"
	"$input/dmsp_iso3c_year.dta"
end
levelsof datasets, local(datasets)

use "$input/iso3c_year_viirs_new.dta", replace
foreach i in `datasets' {
	di "`i'"
	mmerge iso3c year using "`i'"
	drop _merge
}

keep if year >= 1992 & year <= 2022
drop country
save "$input/iso3c_year_base.dta", replace
.