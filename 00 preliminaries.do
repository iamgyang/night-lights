// This is a file that installs all of the packages and sets directories. It
// also provides some options such as turning off variable abbreviations,
// setting numeric digits to always be of type 'double' and it also imports a
// lot of my personal programs. In other languages 'programs' are referred to as
// 'functions'. 

// Broadly, the files are organized such that 00.XXXX means it's a preliminary
// file. 01.XXXX means that it is a file that cleans and imports night lights
// data. 02.XXXX means that it is a file that cleans and imports other data (non
// night lights). 03.XXXX means that it is a file that aids in merging relevant
// cleaned datasets. 04.XXXX means that it is a file pertaining to analysis.

// ------------------------------------------------------------------------------
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
global raw_data    "$root/raw_data"
global intermediate_data    "$root/intermediate_data"
global ntl_input   "$root/raw_data/VIIRS NTL Extracted Data 2012-2020"

// CHANGE THIS!! --- Do we want to install user-defined functions?
loc install_user_defined_functions "No"

if ("`install_user_defined_functions'" == "Yes") {
	foreach i in rangestat wbopendata kountry mmerge outreg2 somersd ///
	asgen moss reghdfe ftools fillmissing eventdd matsort ranktest ivreg2 sepscatter gtools ///
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
syntax varlist(max=1)
keep if `varlist' == "AUS" |`varlist' == "AUT" |`varlist' == "BEL" |`varlist' == "CAN" |`varlist' == "CHL" |`varlist' == "COL" |`varlist' == "CRI" |`varlist' == "CZE" |`varlist' == "DNK" |`varlist' == "EST" |`varlist' == "FIN" |`varlist' == "FRA" |`varlist' == "DEU" |`varlist' == "GRC" |`varlist' == "HUN" |`varlist' == "ISL" |`varlist' == "IRL" |`varlist' == "ISR" |`varlist' == "ITA" |`varlist' == "JPN" |`varlist' == "KOR" |`varlist' == "LVA" |`varlist' == "LTU" |`varlist' == "LUX" |`varlist' == "MEX" |`varlist' == "NLD" |`varlist' == "NZL" |`varlist' == "NOR" |`varlist' == "POL" |`varlist' == "PRT" |`varlist' == "SVK" |`varlist' == "SVN" |`varlist' == "ESP" |`varlist' == "SWE" |`varlist' == "CHE" |`varlist' == "TUR" |`varlist' == "GBR" |`varlist' == "USA"
end

quietly capture program drop drop_oecd
program drop_oecd
syntax varlist(max=1)
drop if `varlist' == "AUS" |`varlist' == "AUT" |`varlist' == "BEL" |`varlist' == "CAN" |`varlist' == "CHL" |`varlist' == "COL" |`varlist' == "CRI" |`varlist' == "CZE" |`varlist' == "DNK" |`varlist' == "EST" |`varlist' == "FIN" |`varlist' == "FRA" |`varlist' == "DEU" |`varlist' == "GRC" |`varlist' == "HUN" |`varlist' == "ISL" |`varlist' == "IRL" |`varlist' == "ISR" |`varlist' == "ITA" |`varlist' == "JPN" |`varlist' == "KOR" |`varlist' == "LVA" |`varlist' == "LTU" |`varlist' == "LUX" |`varlist' == "MEX" |`varlist' == "NLD" |`varlist' == "NZL" |`varlist' == "NOR" |`varlist' == "POL" |`varlist' == "PRT" |`varlist' == "SVK" |`varlist' == "SVN" |`varlist' == "ESP" |`varlist' == "SWE" |`varlist' == "CHE" |`varlist' == "TUR" |`varlist' == "GBR" |`varlist' == "USA"
end

quietly capture program drop label_oecd
program label_oecd
syntax varlist(max=1)
gen OECD = ""
foreach i in "AUS" "AUT" "BEL" "CAN" "CHL" "COL" "CRI" "CZE" "DNK" "EST" "FIN" "FRA" "DEU" "GRC" "HUN" "ISL" "IRL" "ISR" "ITA" "JPN" "KOR" "LVA" "LTU" "LUX" "MEX" "NLD" "NZL" "NOR" "POL" "PRT" "SVK" "SVN" "ESP" "SWE" "CHE" "TUR" "GBR" "USA" {
    replace OECD = "yes" if `varlist' == "`i'"
}
replace OECD = "no" if mi(OECD)
replace OECD = "" if mi(`varlist')
label variable OECD "Is this country in the OECD?"
end

// create categorical variables:
quietly capture program drop create_categ
program create_categ
syntax varlist(min=1)
foreach i of local varlist {
capture confirm numeric variable `i'
// if it's numeric, then first convert to string
if !_rc {
	gen str_`i' = string(`i')
	encode str_`i', gen(cat_`i')
	drop str_`i'
}
// if it's a character, then directly encode
else {
	encode `i', gen(cat_`i')
}
}
end

// Wrapper for the decode function to decode variables to characters. Note that
// this function automatically replaces the decoded variables.
quietly capture program drop decode_vars
program decode_vars
syntax [varlist], [all]
if "`all'" != "" {
	ds, has(vallabel)
	foreach v of varlist `r(varlist)'{
		rename `v' `v'_old
		decode `v'_old, gen(`v')
		/* replace `v' = string(`v'_old) if missing(`v') */
	}
	drop *_old
}
else if "`all'" == "" {
	foreach v of local varlist {
		rename `v' `v'_old
		decode `v'_old, gen(`v')
		/* replace `v' = string(`v'_old) if missing(`v') */
	}
	drop *_old
}
end


