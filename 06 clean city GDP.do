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

// =========================================================================
	
//Import city-level Indonesia GDP dataset
	clear
	import excel ///
		"$raw_data/National Accounts/indonesia_city_gdp_2018_2019.xlsx", ///
		sheet("Sheet1") firstrow
	tempfile yr1
	save `yr1'
	clear
	import excel ///
		"$raw_data/National Accounts/indonesia_city_gdp_2018_2019.xlsx", ///
		sheet("Sheet2") firstrow clear
	append using `yr1'
	sort city year
	gen pop_2 = gdp_nom_M_dollar / gdppc_nom_dollar * (10^6)
	gen ape = abs(pop_2 / pop -1)
	assert ape <= 0.05 | ape ==.
	drop ape
	replace pop = pop_2 if pop==.
	drop pop_2
	export delimited using ///
		"$input/cleaned_indonesia_city_gdp_2018_2019.csv", ///
		replace


























































