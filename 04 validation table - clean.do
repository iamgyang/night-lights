// ================================================================

cd "$input"

// VIIRS cleaned & raw -----------------
// By cleaned, we mean NTL with deletions and without month-ADM2 deletions
use "$input/imf_pwt_GDP_annual.dta", clear
keep iso3c year pwt_rgdpna WDI
rename (pwt_rgdpna WDI) (pwt_rgdpna_check WDI_check)
tempfile pwt_wdi_check
save `pwt_wdi_check'

local del "delete not_delete"

foreach i in `del' {
	use "$input/NTL_GDP_month_ADM2.dta", clear
	keep iso3c gid_2 mean_pix sum_pix year quarter month pol_area pwt_rgdpna ///
	WDI WDI_ppp ox_rgdp_lcu
	if ("`i'" == "delete") {
		drop if sum_pix < 0	    
	}
	rename pol_area sum_area
	collapse (sum) sum_area sum_pix (mean) pwt_rgdpna WDI WDI_ppp ///
	ox_rgdp_lcu, by(year quarter iso3c)
	rename (ox_rgdp_lcu pwt_rgdpna WDI WDI_ppp) (Oxford PWT WDI WDI_ppp)
	sort iso3c year
	collapse (sum) sum_area sum_pix Oxford ///
	(mean) PWT WDI WDI_ppp, by(year iso3c)
	replace Oxford = . if Oxford  == 0
	duplicates tag iso3c year, gen(dup)
	assert dup == 0
	drop dup
	
	// merging back in PWT by year-iso3c should give the exact same results 
	// after collapsing by mean as before collapsing by mean
	mmerge iso3c year using `pwt_wdi_check'
	assert (abs(pwt_rgdpna_check - PWT) < 0.1) | (pwt_rgdpna_check==. & PWT==.)
	assert (abs(WDI_check - WDI) < 0.1) | (WDI_check==. & WDI==.)
	drop *_check _merge
	
	save "collapsed_dataset_`i'.dta", replace
}

tempfile viirs dmsp dmsp_hender dmsp_goldberg

use "collapsed_dataset_delete.dta", clear
rename (sum_area sum_pix) (del_sum_area del_sum_pix)
mmerge iso3c year using "collapsed_dataset_not_delete.dta"
assert _merge == 3
drop _merge

// convert from billions:
foreach i in Oxford PWT WDI {
    replace `i' = `i' * (10^9)
}

// since landmasses don't change over time, make area same area for each 
// country for all years (including those prior to 2012) for the non-cleaned dataset:
bysort iso3c: egen sum_area_repx = max(sum_area)
replace sum_area = sum_area_repx
drop sum_area_repx

// in STATA (and in math) sum of empty set is 0, but here we want it to be missing.
foreach i in del_sum_area del_sum_pix sum_area sum_pix {
	replace `i' = . if `i' ==0
}


save `viirs'


// ---------------------------------------------------------------------
// Merge 
// ---------------------------------------------------------------------

clear
use `viirs'
mmerge iso3c year using "$input/all_dmsp.dta"
drop _merge
mmerge iso3c year using "$input/historical_wb_income_classifications.dta"
drop _merge
mmerge iso3c year using "$input/wb_pop_estimates_cleaned.dta"
drop _merge

// get balanced panel
fillin iso3c year
local thisyear: di %tdDNCY daily("$S_DATE", "DMY")
di "`thisyear'"
local thisyear = substr("`thisyear'", 5, 4)
drop if year > `thisyear'

// confirm that we only have 1 country-year in our panel
bysort iso3c year: gen dup = _n
assert dup == 1

drop _fillin dup

// -------------------------------------------------------------------------
// Extra variables after merging 
// -------------------------------------------------------------------------

// per area variables:
gen del_sum_pix_area = del_sum_pix / del_sum_area
gen sum_pix_area = sum_pix / sum_area
gen sum_light_dmsp_div_area = sum_light_dmsp / sum_area
label variable sum_light_dmsp_div_area "DMSP lights divided / polygon area"

// label variables
label variable del_sum_area "VIIRS (cleaned) polygon area"
label variable del_sum_pix "VIIRS (cleaned) sum of pixels"
label variable Oxford "Oxford real GDP LCU"
label variable PWT "PWT real GDP PPP"
label variable WDI "WDI real GDP LCU"
label variable WDI_ppp "WDI real GDP PPP"
label variable sum_area "lights (raw) polygon area"
label variable sum_pix "VIIRS (raw) sum of pixels"
label variable sum_pix_area "VIIRS (raw) sum of pixels / area"
label variable del_sum_pix_area "VIIRS (cleaned) pixels / area"
label variable sum_light_dmsp "DMSP sum of pixels"
label variable lndn "Log DMSP pixels / area (original)"
label variable lngdpwdilocal "Log WDI real GDP LCU (original)"
label variable exp_hws_wdi "WDI real GDP LCU (original)"
label variable income "WB historical income classification"
label variable poptotal "population (UN)"
label variable sum_light_dmsp_div_area "DMSP sum of pixels / area"
label variable mean_g_ln_lights_gold "Mean Growth in DMSP sum of pixels per capita (Goldberg)"
label variable _gdppercap_constant_ppp_gold "WB real GDP PPP per capita (Goldberg)"
label variable mean_g_ln_gdp_gold "Mean Growth in Log WB real GDP PPP per capita (Goldberg)"
label variable lightpercap_gold "DMSP sum of pixels per capita (Goldberg)"
label variable ln_gdp_gold "Log real GDP PPP per capita (WB, Goldberg)"
label variable sumoflights_gold "DMSP sum of pixels (Goldberg)"

// measure vars
local measure_vars "Oxford PWT WDI WDI_ppp del_sum_pix sum_pix sum_light_dmsp del_sum_pix_area sum_light_dmsp_div_area sum_pix_area sumoflights_gold"

// per capita values
foreach i in `measure_vars' {
    gen `i'_pc = `i' / poptotal
	loc lab: variable label `i'
	di "`lab'"
	label variable `i'_pc "`lab' per capita"
}

foreach l in `measure_vars' {
	local measure_vars "`measure_vars' `l'_pc"
}

// log values
foreach i in `measure_vars' {
    gen ln_`i' = ln(`i')
	loc lab: variable label `i'
	di "`lab'"
	label variable ln_`i' "Log `lab'"
}

// first differences on the logged variables
foreach var of varlist ln_* {
	sort iso3c year
    generate g_`var' = `var' - `var'[_n-1] if iso3c==iso3c[_n-1]
	loc lab: variable label `var'
	di "`lab'"
	label variable g_`var' "Diff. `lab'"
}

// encode categorical variables
gen yr = year
tostring yr, replace
label define income 1 "LIC" 2 "LMIC" 3 "UMIC" 4 "HIC"
encode income, generate(cat_income) label(income) 

label define wbdqcat_3 1 "bad" 2 "ok" 3 "good"
encode wbdqcat_3, generate(cat_wbdqcat_3) label(wbdqcat_3) 

foreach i in iso3c yr wbdqcat {
	di "`i'"
	encode `i', gen(cat_`i')
}

drop yr

// get BASE year for growth regressions:

foreach i in PWT WDI_ppp {
	foreach year_base in 1992 2012 {
		gen base_ln_`i'_pc_`year_base' = ln_`i'_pc if year == `year_base'
		bysort iso3c: egen ln_`i'_pc_`year_base' = max(base_ln_`i'_pc_`year_base')
		drop base_ln_`i'_pc_`year_base'
		label variable ln_`i'_pc_`year_base' "Log `i' real GDP PPP per capita, `year_base'"
	}
}

// create an income variable that is based on the FIRST income present
foreach year_base in 1992 2012 {
	sort cat_iso3c year
	gen cat_income`year_base' = cat_income if year == `year_base'
	bysort cat_iso3c:  fillmissing cat_income`year_base', with(mean)
	capture quietly label define income 1 "LIC" 2 "LMIC" 3 "UMIC" 4 "HIC"
	label value cat_income`year_base' income
	label variable cat_income`year_base' "WB income group, `year_base'"
}

bysort cat_iso3c:  fillmissing cat_wbdqcat_3, with(mean)
gen check = mod(cat_wbdqcat_3, 1)
assert check == 0 | check == .
drop check

save "clean_validation_base.dta", replace












































