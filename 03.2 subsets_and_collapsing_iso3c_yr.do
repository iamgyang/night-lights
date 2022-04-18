// This merges all the relevant country year datasets into one big file. It also
// creates a lot of meaningful variables, such as logged variables, first
// differenced variables, seasonally differenced variables, etc.

local area iso3c
local time year

// COPY OF SUBSETTING AND COLLAPSING CODE (FOR COUNTRY AND YEAR) ----------

clear

// import dataset:
use "$input/iso3c_year_base.dta", clear

// merge in habitable area NTL values:
mmerge iso3c year using "$input/clean_high_density_ntl.dta"
drop _merge

// merge in other NTL versions:
mmerge iso3c year using "$intermediate_data/Aggregated Datasets/Aggregated Datasets/adm0-annual/vrsmn_adm0_ann_2.dta"
drop sum_pix_pagg pol_area_pagg imf_rgdp_lcu_pagg PWT_pagg WDI_pagg ox_anrgdp_lcu_pagg _merge
rename *_pagg *

// merge in BM NTL:
mmerge iso3c year using "$input/bm_iso3c_year.dta"
drop _merge

// PWT is easier to remember:
rename pwt_rgdpna PWT

// the sum of the empty set is 0--so we remove these false 0's
foreach i in del_sum_pix del_sum_area sum_pix_bm_dec pol_area {
    replace `i' = . if `i' == 0
}

// make GDP values dollars (not billions or anything)
// convert from billions:
foreach i in PWT WDI {
    replace `i' = `i' * (10^9)
}

// per area variables:
bys iso3c: fillmissing sum_area
gen del_sum_pix_area = del_sum_pix / del_sum_area
gen sum_pix_area = sum_pix / sum_area
gen sum_light_dmsp_div_area = sum_light_dmsp / sum_area
foreach i of numlist 79(5)99 {
	gen del_sum_pix_`i'_area = del_sum_pix_`i' / del_sum_area_`i'
	gen sum_pix_`i'_area = sum_pix_`i' / sum_area_`i'
}
gen sum_pix_clb_area = sum_pix_clb / sum_area
gen pos_sumpx_area = pos_sumpx / sum_area
gen sum_pix_new_area = sum_pix_new / sum_area
gen sum_pix_bm_area = sum_pix_bm / pol_area
gen sum_pix_bm_dec_area = sum_pix_bm_dec / pol_area

// label variables
label variable rgdppc_ppp_gold "WB real GDP PPP per capita (AGJ)"
label variable del_sum_area "VIIRS (cleaned) polygon area"
label variable del_sum_pix "VIIRS (cleaned) pixels"
label variable del_sum_pix_area "VIIRS (cleaned) pixels / area"
// Black Marble version
label variable sum_pix_bm_dec "BM Dec. pixels"
label variable sum_pix_bm_dec_area "BM Dec. pixels / area"
label variable sum_pix_bm "BM pixels"
label variable sum_pix_bm_area "BM pixels / area"
// calibrated night lights versions
label variable sum_pix_clb "VIIRS (calib.) pixels"
label variable sum_pix "VIIRS (raw) pixels"
label variable pos_sumpx "VIIRS (pos.) pixels"
label variable sum_pix_clb_area "VIIRS (calib.) pixels / area"
label variable sum_pix_area "VIIRS (raw) pixels / area"
label variable pos_sumpx_area "VIIRS (pos.) pixels / area"
label variable sum_pix_new "VIIRS (ann.) pixels / area"
label variable sum_pix_new_area "VIIRS (ann.) pixels / area"
foreach i of numlist 79(5)99 {
	label variable del_sum_pix_`i'_area "VIIRS (cleaned) pixels / area (`i' pct pop density)"
	label variable del_sum_pix_`i' "VIIRS (cleaned) pixels (`i' pct pop density)"
	label variable del_sum_area_`i' "VIIRS (cleaned) polygon area (`i' pct pop density)"
	label variable sum_pix_`i'_area "VIIRS (cleaned) pixels / area (`i' pct pop density)"
	label variable sum_pix_`i' "VIIRS (cleaned) pixels (`i' pct pop density)"
	label variable sum_area_`i' "VIIRS (cleaned) polygon area (`i' pct pop density)"
}
label variable exp_hws_wdi "WDI real GDP LCU (HSW)"
label variable income "WB historical income classification"
label variable lightpercap_gold "DMSP pixels per capita (AGJ)"
label variable ln_gdp_gold "Log real GDP PPP per capita (WB, AGJ)"
label variable lndn "Log DMSP pixels / area (HSW)"
label variable lngdpwdilocal "Log WDI real GDP LCU (HSW)"
/*
note that AGJ in their paper do not label their per capita variables in the 
variable NAME as per capita, but they actually ARE per capita
*/
label variable mean_g_ln_gdp_gold "Growth in Log WB real GDP PPP per capita (AGJ)"
label variable mean_g_ln_lights_gold "Growth in DMSP pixels (AGJ) per capita"
label variable poptotal "population (UN)"
label variable PWT "PWT real GDP PPP"
label variable sum_area "lights (raw) polygon area"
label variable sum_light_dmsp "DMSP pixels (HR)"
label variable sum_light_dmsp_div_area "DMSP pixels / area (HR)"
label variable sumoflights_gold "DMSP pixels (AGJ)"
label variable WDI "WDI real GDP LCU"
label variable WDI_ppp "WDI real GDP PPP"

tempfile dataset_up_to_this_point
save `dataset_up_to_this_point'

// create local "measure_vars" with all quantitative variables of interest:
clear
macro drop measure_vars
clear
input str40 measure_vars
	"del_sum_pix"
	"del_sum_pix_area"
	"del_sum_pix_79_area" // NTL restricted based on 2015 pop density (%tiles)
	"del_sum_pix_79"
	"del_sum_pix_84_area"
	"del_sum_pix_84"
	"del_sum_pix_89_area"
	"del_sum_pix_89"
	"del_sum_pix_94_area"
	"del_sum_pix_94"
	"del_sum_pix_99_area"
	"del_sum_pix_99"
	"sum_pix_bm"
	"sum_pix_bm_area"
	"sum_pix_bm_dec"
	"sum_pix_bm_dec_area"
	"sum_pix_area"
	"sum_pix"
	"sum_pix_area"
	"sum_pix_new"
	"sum_pix_new_area"
	"sum_pix_clb" // other NTL versions based on calibration settings
	"sum_pix_clb_area"
	"pos_sumpx"
	"pos_sumpx_area"
	"PWT"
	"sum_light_dmsp"
	"sum_light_dmsp_div_area"
	"sumoflights_gold"
	"WDI"
	"WDI_ppp"
	"sumoflights_gold"
end
levelsof measure_vars, local(measure_vars)
clear

use `dataset_up_to_this_point'

if ("`area'" == "iso3c") {
	
	// creates per capita values (only makes sense if the collapse variable is 
	// to a country level, as population is measured on a country basis.)
	foreach i in `measure_vars' {
		// if it's an area command, then don't make per capita
		if strpos("`i'", "area") {
		    continue
		}
		gen `i'_pc = `i' / poptotal // Goldberg data has total population scaled by 10,000 (poptotal/100000)
		loc lab: variable label `i'
		di "`lab'"
		label variable `i'_pc "`lab' per capita"
	}
	
	// adds per capita variables to measure vars:
	foreach l in `measure_vars' {
		// if it's an area command, then don't make per capita
		if strpos("`l'", "area") {
		    continue
		}
		local measure_vars "`measure_vars' `l'_pc"
	}
}

// log values

/*
note that Goldberg log lights will differ from its original replication file
because we have new and updated population figures. Specifically, Moldova was 
had been misreporting inaccurate statistics regarding its population for years.
See https://balkaninsight.com/2020/01/16/moldova-faces-existential-population-crisis/
*/
foreach i in `measure_vars' {
	gen ln_`i' = ln(`i')
	loc lab: variable label `i'
	di "`lab'"
	label variable ln_`i' "Log `lab'"
}

// First differences on the logged variables
// before taking first differences, HAVE TO have all years, months, etc.
sort `area' year `time'
if ("`time'" != "year") {
	fillin `area' year `time'
}
else if ("`time'" == "year") {
    fillin `area' year
}
check_dup_id "`area' year `time'"
drop _fillin

// differences in subsequent elements of the time variable 
// (e.g. Feb 2017 minus Jan 2017 or Q2 2021 minus Q1 2021)
foreach var of varlist ln_* {
	sort `area' year `time'
    generate g_`var' = `var' - `var'[_n-1] if ///
		iso3c==iso3c[_n-1]
	loc lab: variable label `var'
	di "`lab'"
	label variable g_`var' "Diff. `lab'"
}

// annual differences (e.g. Jan 2017 minus Jan 2016 or Q1 2021 minus Q1 2020)
foreach var of varlist ln_* {
	sort iso3c `time' year
    generate g_an_`var' = `var' - `var'[_n-1] if ///
		iso3c==iso3c[_n-1] & (year - 1) == (year[_n-1])
	loc lab: variable label `var'
	di "`lab'"
	label variable g_an_`var' "Diff. annual `lab'"
}

// encode categorical variables (numeric --> categorical)
foreach i in year {
	gen str_`i' = string(`i')
	encode str_`i', gen(cat_`i')
	drop str_`i'
}

// encode categorical variables (character --> categorical)
foreach i in wbdqcat iso3c {
    encode `i', gen(cat_`i')
}

// after march covid dummy:
if ("`time'" == "month") {
	gen after_march = 1 if month >= 3
	replace after_march = 0 if month < 3  

	// month has to be ordered
	gen str_month = string(month)
	label define str_month 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10" 11 "11" 12 "12"
	encode str_month, generate(cat_month) label(str_month) 
	drop str_month
}

// income categorical variable
label define income 1 "LIC" 2 "LMIC" 3 "UMIC" 4 "HIC"
encode income, generate(cat_income) label(income) 	

// WB data quality index
label define wbdqcat_3 1 "bad" 2 "ok" 3 "good"
encode wbdqcat_3, generate(cat_wbdqcat_3) label(wbdqcat_3) 

// get BASE year for *annual* growth regressions:
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

// Fill in missing World Bank quality index years with the average of the WB quality index:
bysort cat_iso3c:  fillmissing cat_wbdqcat_3, with(mean)
gen check = mod(cat_wbdqcat_3, 1)
assert check == 0 | check == .
drop check

// label WB data quality
label variable cat_wbdqcat_3 "WB data quality"

// everywhere we have VIIRS percentile built density, we should have VIIRS:
assert !(!mi(del_sum_pix_79_area) & mi(del_sum_pix_area))
assert !(mi(del_sum_pix_79_area) & !mi(del_sum_pix_area))

// // everywhere where VIIRS is not missing for 2017-2020, we should have BM:
// preserve
// keep if inlist(year, 2017, 2018, 2019, 2020) & !mi(del_sum_pix_area)
// keep iso3c year del_sum_pix del_sum_area ln_del_sum_pix g_ln_del_sum_pix_area iso3c year sum_pix_bm_dec sum_pix_bm_dec_area sum_pix_bm_dec_pc ln_sum_pix_bm_dec ln_sum_pix_bm_dec_area ln_sum_pix_bm_dec_pc g_ln_sum_pix_bm_dec g_ln_sum_pix_bm_dec_area g_ln_sum_pix_bm_dec_pc g_an_ln_sum_pix_bm_dec g_an_ln_sum_pix_bm_dec_area g_an_ln_sum_pix_bm_dec_pc
// assert !mi(sum_pix_bm_dec_area)
// restore // !!!!!!!!!!!!!!!!!!!!!!!! ok, this is not true... we're missing some countries (mostly islands?)

save "$input/sample_`area'_`time'_pop_den__allvars2.dta", replace

// check with other version of lights (different calibration) from Parth's data:
use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear





// // find differences between sum_pix, pol_area, WDI, PWT, Oxford, IMF
// rename pol_area_pagg sum_area_pagg
// foreach i in sum_pix sum_area {
//     preserve
// 	di "`i'"
// 	keep `i' iso3c year `i'_pagg
// 	naomit
// 	gen diff_`i' = abs(`i'/`i'_pagg-1)
// 	assert diff_`i' < 0.01
// 	restore
// }


// these are the same values
// gg_ln_sumoflights_gold_pc/g_ln_lights_gold
// gg_ln_lights_gold/g_ln_lights_gold
// gg_ln_sumoflights_gold_pc/g_ln_lights_gold
// ln_sumoflights_gold_pc/ln_lights

// capture drop diff
// gen diff = abs(ln_lights_gold/ln_sumoflights_gold_pc - 1)
// br iso3c year ln_sumoflights_gold_pc ln_lights_gold if diff > 0.01 & !missing(diff)



