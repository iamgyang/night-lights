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

// Capture session to record what happens ------------------------------------

capture log close
set logtype text

local date_time $S_DATE
log using "`date_time'_log.txt", replace
display c(current_date)
display c(current_time)
version 10.1
clear

// Convert files to have Spanish Accents --------------------------------------

// get all the file names from a directory
filelist , dir("$raw_data/Household Surveys/Colombia/") pattern(*.dta)
keep dirname
levelsof dirname, local(dirs_toloop)

foreach dir in `dirs_toloop' {
	clear
	cd "`dir'"
	filelist , dir("$raw_data/Household Surveys/Colombia/") pattern(*.dta) norecur
	levelsof filename, local(files_toloop)

		// convert the files in the directory to have Spanish accents
		foreach file in `files_toloop' {
			clear

			//	make all the accents appear in the STATA file:
			unicode analyze "`file'"
			unicode encoding set "latin1"
			unicode translate "`file'"
		}
	
}

// For 2013-2016, remove all '.dta' files, as files are in txt format --------

foreach x of numlist 2013/2016 {
filelist , dir("$raw_data/Household Surveys/Colombia/`x'") pattern(*Vivienda y Hogares*)
// norecur
gen fullname = dirname + "/" + filename
keep fullname
gen ext = substr(fullname, length(fullname)-2, 3)
keep if ext == "dta"
levelsof fullname, local(files_toloop)
	foreach file in `files_toloop' {
 		erase "`file'"
	}
}

// Grab all the Vivienda y Hogares from the folder ----------------------------

// get all the file names from a directory
filelist , dir("$raw_data/Household Surveys/Colombia/") pattern(*Vivienda y Hogares*)
// norecur
gen fullname = dirname + "/" + filename
keep fullname
gen ext = substr(fullname, length(fullname)-2, 3)
keep if ext == "dta" | ext == "txt"
levelsof fullname, local(files_toloop)

// convert the files in the directory to be DTA files:
dir_convert_2_dta `files_toloop'

// Append all the Vivienda y Hogares files by year: --------------------------
clear
foreach x of numlist 2013/2021 {
	filelist , dir("$raw_data/Household Surveys/Colombia/`x'") pattern(*Vivienda y Hogares*dta)
	// norecur
	gen fullname = dirname + "/" + filename
	keep fullname
	gen ext = substr(fullname, length(fullname)-2, 3)
	keep if ext == "dta"
	levelsof fullname, local(files_toloop)
	foreach file in `files_toloop' {
		di "`file'"
		append using "`file'", force
	}
	save "$input/viv_`x'appended.dta", replace
}


// Clean the resulting appended files -----------------------------------------

foreach x of numlist 2013/2021 {
	use "$input/viv_`x'appended.dta", clear
	
	// use the file extension to create strings that portray the year, month, 
	// and city type:
	replace file_name = subinstr(file_name, "//", "/",.)
	replace file_name = subinstr(file_name, "//", "/",.)
	drop if file_name == ""
	gen x1 = strpos(file_name, "Colombia")
	// get a substring within a string; we know 'Colombia' is 8 characters 
	// long, so +1.
	gen year = substr(file_name, x1+9, 4) 
	// function allows you to do a string search starting at a specific point
	gen x2 = ustrpos(file_name, "/", x1+15) 
	// get a substring within a string
	gen month = substr(file_name, x1+14, x2-x1-14-4) 
	// this function does a string search BACKWARDS
	gen x3 = strrpos(file_name, "/") 
	gen location_type = substr(file_name, x3+1, length(file_name))
	replace location_type = subinstr(location_type, " - Vivienda y Hogares", "",.)
	replace location_type = subinstr(location_type, ".dta", "",.)
	quietly forval j = 0/9 {
		replace location_type = subinstr(location_type, "`j'", "", .)
	}
	replace location_type = subinstr(location_type, "╡rea", "Urban City",.)
	drop x1 x2 x3 file_names

	// re-label the months
	replace month =  "1" if month ==  "Enero"
	replace month =  "2" if month ==  "Febrero"
	replace month =  "3" if month ==  "Marzo"
	replace month =  "4" if month ==  "Abril"
	replace month =  "5" if month ==  "Mayo"
	replace month =  "6" if month ==  "Junio"
	replace month =  "7" if month ==  "Julio"
	replace month =  "8" if month ==  "Agosto"
	replace month =  "9" if month ==  "Septiembre"
	replace month =  "10" if month ==  "Octubre"
	replace month =  "11" if month ==  "Noviembre"
	replace month =  "12" if month ==  "Diciembre"
	destring year month, replace force float
	
	// Convert certain variables from string to numeric
	foreach i in regis clase mes area dpto {
		capture quietly destring `i', replace
	}
	
	// save file
	save "$input/colombia`x'cleaned.dta", replace
}


// append all the years
use "$input/colombia2020cleaned.dta", clear
foreach x of numlist 2013/2019 2021 {
	append using "$input/colombia`x'cleaned.dta", force
}
// Convert variables to non-numeric:
tostring regis clase mes dpto, replace
save "$input/cleaned_colombia_vivienda.dta", replace

// convert to have Spanish accents
clear
capture noisily unicode erasebackups, badidea
cd "$input"
unicode analyze cleaned_colombia_vivienda.dta
unicode encoding set "latin1"
unicode translate cleaned_colombia_vivienda.dta
clear

use cleaned_colombia_vivienda.dta
destring regis clase mes dpto, replace
save cleaned_colombia_vivienda.dta, replace

// Perform checks ------------------------------------------------------------

use cleaned_colombia_vivienda.dta

// directorio == household ID
// fex == weights
// there should be no missing IDs in each dataset
gen check = missing(directorio)
assert(check == 0)
drop check

gen check = missing(fex_c_2011)
assert(check == 0)
drop check

// there should be no missing departamento (ADM1 location)
gen check = missing(dpto)
assert(check == 0)
drop check

// across each year each column should have similar percent missing values
if "`do_checks'" == "yes" {
	pause on
	foreach var of varlist _all {
		capture drop check
		gen check = 1 if missing(`var')
		replace check = 0 if !missing(`var')
		cls
		tab check year, column
		pause "`var'"
		capture drop check
	}
	pause off    
}

// all months and years should be represented
tab year month, matcell(check)
matrix list check
svmat check
gen rownum1 = _n
replace rownum1 = 2012 + rownum1
foreach x of varlist check* {
	di "`x'"
	assert `x' > 25000 if rownum1 < 2020
}
drop check*

display c(current_time)
log close
exit, clear



