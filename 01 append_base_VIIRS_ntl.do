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
if ("$import_nightlights" == "yes") {
	import delimited "$ntl_input/NTL_adm2_2012.csv", encoding(UTF-8) clear 
	tempfile ntl_append
	save `ntl_append'

	foreach yr in 2013 2014 2015 2016 2017 2018 2019 2020 {
		import delimited "$ntl_input/NTL_adm2_`yr'.csv", encoding(UTF-8) clear 
		tempfile ntl_append_`yr'
		save `ntl_append_`yr''
		use `ntl_append', clear
		append using `ntl_append_`yr''
		save `ntl_append', replace
	}
	use `ntl_append'

// clean dates
	gen date2 = date(time, "M20Y")	
	format date2 %td
	gen yq = qofd(date2)
	format yq %tq

// in other datasets, Kosovo is XKX
	rename gid_0 iso3c
	replace iso3c = "XKX" if iso3c == "XKO"

// check that GID is the same as ISO ID
	preserve
	keep iso3c name_0
	duplicates drop
	kountry name_0, from(other) stuck
	ren(_ISO3N_) (temp)
	kountry temp, from(iso3n) to(iso3c)
	sort _ISO3C_
	gen iso_same = _ISO3C_ == iso3c
	replace iso_same = 1 if _ISO3C_ == ""
	assert iso_same == 1
	restore
}
else if ("$import_nightlights" != "yes") {
	use "$input/NTL_appended.dta", clear
}

// Clean up: 
	drop v1
	replace gadmid = ""  if gadmid  == "NA"
	replace iso = ""     if iso     == "NA"
	replace gid_2 = ""   if gid_2   == "NA"
	replace gid_1 = ""   if gid_1   == "NA"
	replace name_0 = ""  if name_0  == "NA"
	replace iso3c = ""   if iso3c 	== "NA"
	replace name_1 = ""  if name_1 	== "NA"

// Some ISO codes are in the ISO variable, as opposed to the ISO3C variable. 
// Similarly, we are missing some GADM codes
	replace iso3c = iso if (iso != "" & iso3c == "")
	replace gid_2 = "gadm" + gadmid if (gid_2 == "" & gadmid!="")

// save
	save "$input/NTL_appended.dta", replace
	
// NEW VIIRS (annual) ----------------------------------------------------

import delimited "$raw_data/VIIRS NTL Extracted Data 2 2012-2020/VIIRS_annual2.csv", clear

// generate time variable and adjust for the same names as the prior dataset
	tostring year, gen(time)
	replace time = substr(time, 3, 4)
	replace time = "Jan_" + time
	rename (r_mean r_sd r_sum) (mean_pix std_pix sum_pix)

// clean dates
	gen date2 = date(time, "M20Y")	
	format date2 %td
	gen yq = qofd(date2)
	format yq %tq

// in other datasets, Kosovo is XKX
	replace iso3c = "XKX" if iso3c == "XKO"

// check that GID is the same as ISO ID
	preserve
	keep iso3c name_0
	duplicates drop
	kountry name_0, from(other) stuck
	ren(_ISO3N_) (temp)
	kountry temp, from(iso3n) to(iso3c)
	sort _ISO3C_
	gen iso_same = _ISO3C_ == iso3c
	replace iso_same = 1 if _ISO3C_ == ""
	assert iso_same == 1
	restore
	
// Clean up: 
	replace gid_2 = ""   if gid_2   == "NA"
	replace gid_1 = ""   if gid_1   == "NA"
	replace name_0 = ""  if name_0  == "NA"
	replace iso3c = ""   if iso3c 	== "NA"
	replace name_1 = ""  if name_1 	== "NA"

// Save NEW VIIRS DATASET
	save "$input/NTL_appended2.dta", replace
	






































