local area iso3c
local time year

// COPY OF SUBSETTING AND COLLAPSING CODE (FOR COUNTRY AND YEAR) ----------

clear
input str40 measure_vars
	"del_sum_pix"
	"del_sum_pix_area"
	"PWT"
	"sum_light_dmsp"
	"sum_light_dmsp_div_area"
	"sumoflights_gold"
	"WDI"
	"WDI_ppp"
end
tempfile measure_vars_tempfile
save `measure_vars_tempfile'

// import dataset:
use "$input/iso3c_year_base.dta", clear

// PWT is easier to remember:
rename pwt_rgdpna PWT

// the sum of the empty set is 0--so we remove these false 0's
foreach i in del_sum_pix del_sum_area {
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
gen sum_light_dmsp_div_area = sum_light_dmsp / sum_area

// label variables
label variable _gdppercap_constant_ppp_gold "WB real GDP PPP per capita (AGJ)"
label variable del_sum_area "VIIRS (cleaned) polygon area"
label variable del_sum_pix "VIIRS (cleaned) pixels"
label variable del_sum_pix_area "VIIRS (cleaned) pixels / area"
label variable exp_hws_wdi "WDI real GDP LCU (HSW)"
label variable income "WB historical income classification"
label variable lightpercap_gold "DMSP pixels per capita (AGJ)"
label variable ln_gdp_gold "Log real GDP PPP per capita (WB, AGJ)"
label variable lndn "Log DMSP pixels / area (HSW)"
label variable lngdpwdilocal "Log WDI real GDP LCU (HSW)"
label variable mean_g_ln_gdp_gold "Mean Growth in Log WB real GDP PPP per capita (AGJ)"
label variable mean_g_ln_lights_gold "Mean Growth in DMSP pixels per capita (AGJ)"
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
use `measure_vars_tempfile'
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
		gen `i'_pc = `i' / poptotal
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

save "$input/sample_`area'_`time'_pop_den_`pop_den'_allvars2.dta", replace







