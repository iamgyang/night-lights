// Macros ----------------------------------------------------------------

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

// ===========================================================================

cd "$input"

// Merge with the expansion factor -------------------------------------------

use "cleaned_colombia_full.dta", clear

// Make sure have no duplicated IDs:
// we have to drop Area (I.E. the 13 cities) here because they duplicate the ID 
// (directorio secuencia_p year)
drop if location_type == "Area" 
bysort directorio secuencia_p year: gen dup = _N
assert dup == 1
drop dup

mmerge directorio secuencia_p year using expansion_factor.dta
br if _m != 3
// why are there IDs in merge that are only in the weights, but not in the actual data? 
//  - we're not using all the data properly
//  - we're missing some data from 2020 which was INTENDED to be surveyed and weighted differently?
//  - yah, tbh I don't know
keep if _m == 3

save "cleaned_colombia_full.dta", replace
