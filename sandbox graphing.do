// 0. Preliminaries

clear all 
set more off
set varabbrev off
set scheme s1mono
set type double, perm

// CHANGE THIS!! --- Define your own directories:
foreach user in "`c(username)'" {
	global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
}

global code        "$root/HF_measures/code"
global input       "$root/HF_measures/input"
global output      "$root/HF_measures/output"
global raw_data    "$root/raw-data"
global ntl_input   "$root/raw-data/VIIRS NTL Extracted Data 2012-2020"

// CHANGE THIS!! --- Do we want to install user-defined functions?
loc install_user_defined_functions "No"

if ("`install_user_defined_functions'" == "Yes") {
	foreach i in rangestat wbopendata kountry mmerge outreg2 somersd ///
	asgen moss reghdfe ftools fillmissing {
		ssc install `i'
	}
}

// CHANGE THIS!! --- Do we want to import nightlights from the tabular raw data? 
// (takes a long time)
global import_nightlights "yes"

// PERSONAL PROGRAMS ----------------------------------------------

// checks if IDs are duplicated
quietly capture program drop check_dup_id
program check_dup_id
	args id_vars
	preserve
	keep `id_vars'
	sort `id_vars'
    quietly by `id_vars':  gen dup = cond(_N==1,0,_n)
	assert dup == 0
	restore
	end

// drops all missing observations
quietly capture program drop naomit
program naomit
	foreach var of varlist _all {
		drop if missing(`var')
	}
	end

// creates new variable of ISO3C country codes
quietly capture program drop conv_ccode
program conv_ccode
args country_var
	kountry `country_var', from(other) stuck
	ren(_ISO3N_) (temp)
	kountry temp, from(iso3n) to(iso3c)
	drop temp
	ren (_ISO3C_) (iso3c)
end

// create a group of logged variables
quietly capture program drop create_logvars
program create_logvars
args vars

foreach i in `vars' {
    gen ln_`i' = ln(`i')
	loc lab: variable label `i'
	di "`lab'"
	label variable ln_`i' "Log `lab'"
}
end

// ================================================================

// SANDBOX GRAPHING ========================


// Log growth in GDP ~ Log NTL / area -------------------------------------
use "$input/clean_validation_base.dta", clear

drop if g_ln_WDI < - 0.2
drop if g_ln_WDI > 0.2
gen growth_neg = g_ln_WDI < 0 
regress g_ln_WDI g_ln_del_sum_pix_area c.growth_neg##c.g_ln_del_sum_pix_area, robust

#delimit ;
tw scatter g_ln_del_sum_pix_area g_ln_WDI ||
	lfit g_ln_del_sum_pix_area g_ln_WDI if g_ln_WDI>0 ||
	lfit g_ln_del_sum_pix_area g_ln_WDI if g_ln_WDI<0 
	;
#delimit cr
graph export "$input/dot_log_growth_GDP_vs_NTL_div_area.png", replace

// SCATTERPLOT Log pixels ~ Oxford -----------------------------------------
use "$input/clean_validation_monthly_base.dta", clear
gen ind_oxcgrtstringency = oxcgrtstringency>0
#delimit ;
tw scatter ln_sum_pix oxcgrtstringency ||
	lpoly ln_sum_pix oxcgrtstringency if ind_oxcgrtstringency>0 ||
	;
#delimit cr
graph export "$input/dot_log_pix_vs_oxford.png", replace
	
// 	lpoly ln_sum_pix oxcgrtstringency || 
// 	lfit ln_sum_pix oxcgrtstringency if ind_oxcgrtstringency>0 ||
// 	lfit ln_sum_pix oxcgrtstringency


// TIME SERIES DISCONTUINUITY RUNNING VARIABLE PLOT -----------------------

use "$input/NTL_GDP_month_ADM2.dta", clear
keep iso3c gid_2 mean_pix sum_pix year month pol_area
keep if !missing(sum_pix)
collapse (sum) sum_pix, by(iso3c year month)
gen ln_sum_pix = ln(sum_pix)
keep iso3c year month ln_sum_pix
naomit
keep if year == 2019 | year == 2020
tostring year month, replace
gen yrmo = year + month
drop year month
reshape wide ln_sum_pix, i(iso3c) j(yrmo, string)
naomit
reshape long ln_sum_pix, i(iso3c) j(yrmo, string)
gen month = substr(yrmo, 5, 1)
gen year = substr(yrmo, 1, 4)
drop yrmo
destring year month, replace
collapse (mean) ln_sum_pix, by(month year)
// reshape wide ln_sum_pix, i(month) j(year, string)
twoway (line ln_sum_pix month if year == 2019) (line ln_sum_pix month if year == 2020), legend(order(1 "2019" 2 "2020"))
graph export "$input/line_log_pix_vs_month.png", replace

use "$input/NTL_GDP_month_ADM2.dta", clear
keep iso3c gid_2 mean_pix sum_pix year month pol_area
keep if !missing(sum_pix)
collapse (sum) sum_pix, by(iso3c year month)
gen ln_sum_pix = ln(sum_pix)
keep iso3c year month sum_pix
naomit
keep if year == 2019 | year == 2020
tostring year month, replace
gen yrmo = year + month
drop year month
reshape wide sum_pix, i(iso3c) j(yrmo, string)
naomit
reshape long sum_pix, i(iso3c) j(yrmo, string)
gen month = substr(yrmo, 5, 1)
gen year = substr(yrmo, 1, 4)
drop yrmo
destring year month, replace
collapse (mean) sum_pix, by(month year)
// reshape wide sum_pix, i(month) j(year, string)
twoway (line sum_pix month if year == 2019) (line sum_pix month if year == 2020), legend(order(1 "2019" 2 "2020"))
graph export "$input/line_pix_vs_month.png", replace

// DISCONTINUITY ---------------------------

use "$input/adm2_month_derived.dta", clear

drop if objectid == ""
check_dup_id "objectid year month"

keep if year == 2020 | year == 2019

#delimit ;
tw scatter ln_sum_pix_area month ||
	lpoly ln_sum_pix_area month if month < 3 & year == 2020 ||
	lpoly ln_sum_pix_area month if month >= 3  & year == 2020 ||
	lpoly ln_sum_pix_area month if month < 3 & year == 2019 ||
	lpoly ln_sum_pix_area month if month >= 3  & year == 2019
	;
#delimit cr
graph export "$input/dot_log_pix_area_vs_month.png", replace

// SCATTERPLOT MATRIX PLOT -----------------------
use "$input/clean_validation_monthly_base.dta", clear

graph matrix sum_pix cornet_business cornet_health_monitor cornet_health_resource cornet_mask cornet_school cornet_social_dist oxcgrtstringency oxcgrtgovernmentresponse oxcgrtcontainmenthealth oxcgrteconomicsupport ln_sum_pix
graph export "scatterplot_matrix_COVID_base.png", replace

use "$input/clean_validation_monthly_base.dta", clear
foreach i of varlist cornet* oxcgrt* {
    gen ln_`i' = ln(`i')
	loc lab: variable label `i'
	di "`lab'"
	label variable ln_`i' "Log `lab'"
}

graph matrix sum_pix ln_*
graph export "$input/scatterplot_matrix_COVID_base_log.png", replace





















