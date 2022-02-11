// so, this takes EONS to run. I've instead moved parts of it to 
// 03.3 subsets_and_collapsing_iso3c_yr.do for only country-year collapsing.
// also for high density population figures, I've moved that code to R for speed.

// also, somehow this code throws errors on my assert command (need to debug)

global sample = 1

clear
input str40 measure_vars
	"PWT"
	"WDI"
	"WDI_ppp"
	"del_sum_pix"
	"sum_pix"
	"sum_light_dmsp"
	"del_sum_pix_area"
	"sum_light_dmsp_div_area"
	"sum_pix_area"
	"sumoflights_gold"
	"del_sum_pix"
	"sum_pix"
	"del_sum_pix_area"
	"sum_pix_area"
end
tempfile measure_vars_tempfile
save `measure_vars_tempfile'

foreach pop_den in 95 { //1
foreach area in objectid { //iso3c
foreach time in quarter { //year month 

if ($sample == 1) {
	use "$input/sample_adm2_month_allvars.dta", clear
	
	// make sure that we only have USA and ZWE
	levelsof iso3c, local(iso_check1)
	local iso_check2: word count `iso_check1'
	assert `iso_check2' == 2
}
else {
	use "$input/adm2_month_allvars.dta", clear
	
	// make sure that we have >= 100 countries
	levelsof iso3c, local(iso_check1)
	local iso_check2: word count `iso_check1'
	assert `iso_check2' >=100
}

// drop if missing(`area') | missing(`time')

if ("`area'" == "objectid" & "`time'" == "month") {
    continue
}

// Get population density figures
// population density is population divided by area:
gen pop_density15 = sum_wpop / sum_area
label variable pop_density15 "2015 population density (pop/polygon area)"

// get the Xth percentile population density figure per year:
sort year
by year: egen p`pop_den'_pop_den = pctile(pop_density15), p(`pop_den')

// IF population density is below the Xth percentile, delete it:
// delete things based on population density
if (`pop_den' != 1) {
keep if pop_density15 >= p`pop_den'_pop_den
}

// Collapse -------------------------------------------------------------

pause

#delimit ;

collapse 

/* VIIRS is summed */
(sum)
sum_pix
sum_area
del_sum_pix
del_sum_area

/* everything else is a mean, unless I'm going from quarterly GDP to annual
GDP values*/
`addtl_gdp_sum'

(mean)
std_pix 
std_pix_new
sum_pix_new
del_sum_pix_new
del_sum_area_new

sum_light_dmsp
wbdqtotal
lndn 
lngdpwdilocal 
exp_hws_wdi
_gdppercap_constant_ppp_gold
sumoflights_gold
ln_gdp_gold
lightpercap_gold
mean_g_ln_gdp_gold
mean_g_ln_lights_gold
poptotal

stringencyindex
governmentresponseindex containmenthealthindex economicsupportindex
restr_business restr_health_monitor restr_health_resource restr_mask
restr_school restr_social_dist

pwt_rgdpna
imf_rgdp_lcu
WDI
WDI_ppp

, by(`area' year `time' wbdqcat income)

;
#delimit cr

// PWT is easier to remember:
rename pwt_rgdpna PWT

// the sum of the empty set is 0--so we remove these false 0's
foreach i in sum_pix sum_area del_sum_pix del_sum_area {
    replace `i' = . if `i' == 0
}

// make GDP values dollars (not billions or anything)
// convert from billions:
foreach i in PWT WDI {
    replace `i' = `i' * (10^9)
}
// per area variables:
gen del_sum_pix_area = del_sum_pix / del_sum_area
gen sum_pix_area = sum_pix / sum_area
gen sum_pix_new_area = sum_pix_new / sum_area
gen sum_light_dmsp_div_area = sum_light_dmsp / sum_area

// label variables
label variable del_sum_area "VIIRS (cleaned) polygon area"
label variable del_sum_pix "VIIRS (cleaned) sum of pixels"
label variable sum_area "lights (raw) polygon area"
label variable sum_pix "VIIRS (raw) sum of pixels"
label variable sum_pix_area "VIIRS (raw) sum of pixels / area"
label variable del_sum_pix_area "VIIRS (cleaned) pixels / area"
label variable sum_light_dmsp_div_area "DMSP sum of pixels / area"
label variable del_sum_area "VIIRS (cleaned) polygon area"
label variable del_sum_pix "VIIRS (cleaned) sum of pixels"
// label variable Oxford "Oxford real GDP LCU"
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

// rename + label stringency index data
rename restr* cornet*
rename *index oxcgrt*

label variable cornet_business "business restriction index (Coronanet)"
label variable cornet_health_monitor "health monitoring index (Coronanet)"
label variable cornet_health_resource "health resources index (Coronanet)"
label variable cornet_mask "masking index (Coronanet)"
label variable cornet_school "school restriction index (Coronanet)"
label variable cornet_social_dist "social distancing index (Coronanet)"
label variable oxcgrtstringency "composite stringency index (Oxford)"
label variable oxcgrtgovernmentresponse "government response index (Oxford)"
label variable oxcgrtcontainmenthealth "health containment index (Oxford)"
label variable oxcgrteconomicsupport "economic support index (Oxford)"

tempfile dataset_up_to_this_point
save `dataset_up_to_this_point'

// create local "measure_vars" with all quantitative variables of interest:
clear
macro drop measure_vars
clear
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

// Fill in missing world bank quality index years with the average of the WB quality index:
pause
bysort cat_iso3c:  fillmissing cat_wbdqcat_3, with(mean)
gen check = mod(cat_wbdqcat_3, 1)
assert check == 0 | check == .
drop check

// label WB data quality
label variable cat_wbdqcat_3 "WB data quality"

save "$input/sample_`area'_`time'_pop_den_`pop_den'_allvars2.dta", replace
}
}
}










