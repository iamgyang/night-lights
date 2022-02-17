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

cd "$input"

// Create an ADM1-rural-urban-month dataset (collapse) ------------------------

use "cleaned_colombia_full_1.dta", replace

drop p5090s1

// make the missing values what they actually are for p5130 and p5140
replace p5130 = . if p5130 == 99 | p5130 == 98
replace p5140 = . if p5140 == 99 | p5140 == 98

// merge estimated rent payments with actual rent payments (each mutually exclusive)
egen p5130_alt = rowmean(p5130 p5140)
replace p5130 = p5130_alt
drop p5130_alt
label variable p5130 "estimated or actual rent payment"
drop p5140

preserve
desc, replace clear
export delimited "colombia_variables_definitions_part1.csv", replace
restore

// one-hot encode everything
ds, has(type string)
foreach v of varlist `r(varlist)'{
	tab `v', gen(`v'_)
	if ("`v'"!="location_type") {
		drop `v'
	}
}
drop location_type_*

preserve
desc, replace clear
export delimited "colombia_variables_definitions_part2.csv", replace
restore

// collapse by mean:
ds, has(type numeric)
local to_collapse "`r(varlist)'"
di "`to_collapse'"
local to_collapse : subinstr local to_collapse "location_type" "", word
local to_collapse : subinstr local to_collapse "month" "", word
local to_collapse : subinstr local to_collapse "year" "", word
local to_collapse : subinstr local to_collapse "dpto" "", word
local to_collapse : subinstr local to_collapse "directorio" "", word
local to_collapse : subinstr local to_collapse "fex_c_2011" "", word
local to_collapse : subinstr local to_collapse "regis" "", word
local to_collapse : subinstr local to_collapse "clase" "", word
local to_collapse : subinstr local to_collapse "mes" "", word
di "`to_collapse'"

// we collapse by Department (ADM1)
gcollapse (mean) `to_collapse' [aweight = fex_dpto_c], ///
	by(location_type month year dpto area)

save "cleaned_colombia_full_3.dta", replace


