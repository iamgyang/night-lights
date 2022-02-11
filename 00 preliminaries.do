// 0. Preliminaries

clear all 
set more off
set varabbrev off
set scheme s1mono
set type double, perm

// CHANGE THIS!! --- Define your own directories:
global root        "C:/Users/`c(username)'/Dropbox/CGD GlobalSat/"
global code        "$root/HF_measures/code"
global input       "$root/HF_measures/input"
global output      "$root/HF_measures/output"
global overleaf	   "C:/Users/`c(username)'/Dropbox/Apps/Overleaf/Night Lights"
global raw_data    "$root/raw-data"
global intermediate_data    "$root/intermediate_data"
global ntl_input   "$root/raw-data/VIIRS NTL Extracted Data 2012-2020"

// CHANGE THIS!! --- Do we want to install user-defined functions?
loc install_user_defined_functions "No"

if ("`install_user_defined_functions'" == "Yes") {
	foreach i in rangestat wbopendata kountry mmerge outreg2 somersd ///
	asgen moss reghdfe ftools fillmissing eventdd matsort ranktest ivreg2 sepscatter ///
	ivreghdfe{
		capture ssc install `i'
	}
}

// installation for ivreghdfe:
// * Install ftools (remove program if it existed previously)
// cap ado uninstall ftools
// net install ftools, from("https://raw.githubusercontent.com/sergiocorreia/ftools/master/src/")
//
// * Install reghdfe
// cap ado uninstall reghdfe
// net install reghdfe, from("https://raw.githubusercontent.com/sergiocorreia/reghdfe/master/src/")
//
// * Install ivreg2, the core package
// cap ado uninstall ivreg2
// ssc install ivreg2
//
// * Finally, install this package
// cap ado uninstall ivreghdfe
// net install ivreghdfe, from(https://raw.githubusercontent.com/sergiocorreia/ivreghdfe/master/src/)



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

// function that drops or keeps OECD countries

quietly capture program drop keep_oecd
program keep_oecd
syntax, iso_var(namelist)
keep if `iso_var' == "AUS" |`iso_var' == "AUT" |`iso_var' == "BEL" |`iso_var' == "CAN" |`iso_var' == "CHL" |`iso_var' == "COL" |`iso_var' == "CRI" |`iso_var' == "CZE" |`iso_var' == "DNK" |`iso_var' == "EST" |`iso_var' == "FIN" |`iso_var' == "FRA" |`iso_var' == "DEU" |`iso_var' == "GRC" |`iso_var' == "HUN" |`iso_var' == "ISL" |`iso_var' == "IRL" |`iso_var' == "ISR" |`iso_var' == "ITA" |`iso_var' == "JPN" |`iso_var' == "KOR" |`iso_var' == "LVA" |`iso_var' == "LTU" |`iso_var' == "LUX" |`iso_var' == "MEX" |`iso_var' == "NLD" |`iso_var' == "NZL" |`iso_var' == "NOR" |`iso_var' == "POL" |`iso_var' == "PRT" |`iso_var' == "SVK" |`iso_var' == "SVN" |`iso_var' == "ESP" |`iso_var' == "SWE" |`iso_var' == "CHE" |`iso_var' == "TUR" |`iso_var' == "GBR" |`iso_var' == "USA"
end

quietly capture program drop drop_oecd
program drop_oecd
syntax, iso_var(namelist)
drop if `iso_var' == "AUS" |`iso_var' == "AUT" |`iso_var' == "BEL" |`iso_var' == "CAN" |`iso_var' == "CHL" |`iso_var' == "COL" |`iso_var' == "CRI" |`iso_var' == "CZE" |`iso_var' == "DNK" |`iso_var' == "EST" |`iso_var' == "FIN" |`iso_var' == "FRA" |`iso_var' == "DEU" |`iso_var' == "GRC" |`iso_var' == "HUN" |`iso_var' == "ISL" |`iso_var' == "IRL" |`iso_var' == "ISR" |`iso_var' == "ITA" |`iso_var' == "JPN" |`iso_var' == "KOR" |`iso_var' == "LVA" |`iso_var' == "LTU" |`iso_var' == "LUX" |`iso_var' == "MEX" |`iso_var' == "NLD" |`iso_var' == "NZL" |`iso_var' == "NOR" |`iso_var' == "POL" |`iso_var' == "PRT" |`iso_var' == "SVK" |`iso_var' == "SVN" |`iso_var' == "ESP" |`iso_var' == "SWE" |`iso_var' == "CHE" |`iso_var' == "TUR" |`iso_var' == "GBR" |`iso_var' == "USA"
end



























