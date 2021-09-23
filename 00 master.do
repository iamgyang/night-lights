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
global ntl_input   "$root/raw-data/NTL Extracted Data 2012-2020"

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
	ren (_ISO3C_) (iso)
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
// 1. National Accounts 
// 	a. 1 country-year 
// 		i. 1 import ntl 
			do "$code/01 append_base_VIIRS_ntl.do"
// 		ii. 2 clean gdp & population 
			do "$code/02 clean national GDP measures.do"
			do "$code/03 clean_population_measures.do"
// 		iii. 3 analysis - validation 
			do "$code/04 analysis national GDP measures.do"
			do "$code/05 validation table - clean.do"
			do "$code/05 validation table - regressions.do"
// 	b. 2 city-year 
		do "$code/06 clean city GDP.do"
		do "$code/07 clean city nightlights.do" // |------ this file needs to be edited
// 	c. 3 china subnat'l accounts 
		do "$code/08 clean china.do"
// 2. Household Survey 
// 	a. 1 colombia  // |------ these files are in progress
		do "$code/09 data list variable labels in Colombia.do" 
		do "$code/10 col - clean expansion factor dpto weights.do"
		do "$code/11 col - clean vivienda.do"
		do "$code/12 col - clean ocupados.do"
		// tbd: new file: 13 col - clean caracteristicas generales
		do "$code/14 col - merge together.do"
		do "$code/15 col - to english - 1.do"
		do "$code/16 col - collapse to adm-month.do"
		do "$code/17 col - to english - 2.do"
		do "$code/999 col - todo.do"
// 	b. 2 LSMS
		do "$code/18 data list variable labels in LSMS.do"

// ================================================================

// For the Columbia folder, Dropbox, IF want to rewind, do it to 11:59 AM 7/22/2021
// C:\Users\`user'\Dropbox\CGD GlobalSat\HF_measures\input\Household Surveys\Colombia
// 		These files do a few things: 
// 			 - converts txt files to dta files 
// 			 - appends all the colombia datasets together 
// 			 - converts spanish datasets to english
// 			 - collapses the data using the survey weights to an ADM1-month level
//
// working on how to merge and select only the variables we need


