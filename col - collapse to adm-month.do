// Macros ---------------------------------------------------------------------
foreach user in "`c(username)'" {
	global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
	global hf_input "$root/HF_measures/input/"
	global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
}
set more off 
cd "$hf_input"

// Create an ADM1-rural-urban-month dataset (collapse) ------------------------

use cleaned_colombia_full_1.dta, replace

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
export delimited colombia_variables_definitions_part1.csv, replace
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
export delimited colombia_variables_definitions_part2.csv, replace
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
collapse (mean) `to_collapse' [aweight = fex_dpto_c], ///
	by(location_type month year dpto area)

save cleaned_colombia_full_3.dta, replace


