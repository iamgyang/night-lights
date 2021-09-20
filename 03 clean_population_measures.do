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

*** =================================================================

cd "$input"

// WDI population estimates --------------------------------------------------
clear
wbopendata, clear nometadata long indicator(SP.POP.TOTL) year(1960:2021)
drop if regionname == "Aggregates"
keep countrycode year sp_pop_totl
rename (countrycode sp_pop_totl) (iso3c poptotal)
fillin iso3c year
drop _fillin
sort iso3c year
bysort iso3c year: gen dup = _n
assert dup == 1
drop dup
br if poptotal ==.
replace poptotal = poptotal[_n-1] if poptotal == . & iso3c[_n] == iso3c[_n-1]

save "wb_pop_estimates_cleaned.dta", replace









