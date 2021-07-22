// TO DO -----------------------------------------------------------------
// 2013 is missing ~2% of the for variables once BEFORE "p4010", up to "p4030s4a1"
// the txt ones are missing for regis, clase, mes, area
// the dta ones are missing p6006

// there should be no error messages coming from STATA that you don't understand
// all months and years should be represented
// within each month and year, there should be no missing datasets
// within each month and year, there should be relative continuity of the LEVELs of the variable
// all months and years should have 3 parts: from Area, Cabecera, and Surroundings

// CHECK IF IT HAS SOMETHING TO DO WITH STRING VS. NUMERIC

// TO DO -----------------------------------------------------------------

// This file attempts to clean some of the household survey datasets 
// from Colombia.

// For the Columbia folder, Dropbox, IF want to rewind, do it to 11:59 AM 7/22/2021
// C:\Users\`user'\Dropbox\CGD GlobalSat\HF_measures\input\Household Surveys\Colombia

*** Macros -----------------------------------------------------------------
	cls
	foreach user in "`c(username)'" {
		global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
		global hf_input "$root/HF_measures/input/"
		global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
	}

	global outreg_file_natl_yr "$hf_input/natl_reg_hender_28.xls"
	global outreg_file_compare_12_13 "$hf_input/outreg_file_compare_2012_2013_v2.xls"
	
	clear all
	set more off 

	cd "$hf_input"
	
	cls

// capture session to see what happens ------------------------------------

cd "$hf_input"
capture log close
set logtype text
log using lightspaper_replicationlog.txt, replace
display c(current_time)
version 10.1
clear

// Convert files to have Spanish Accents --------------------------------------

// get all the file names from a directory
filelist , dir("$hf_input/Household Surveys/Colombia/") pattern(*.dta)
keep dirname
levelsof dirname, local(dirs_toloop)

foreach dir in `dirs_toloop' {
	clear
	cd "`dir'"
	filelist , dir("$hf_input/Household Surveys/Colombia/") pattern(*.dta) norecur
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

// For 2013-2016, remove all '.dta' files, as files are in txt format ---------

// I accidently didn't search for 'txt' at the END of the file, so I created
// a lot of files that had .dta.dta in them in these years.

foreach x of numlist 2013/2016 {
filelist , dir("$hf_input/Household Surveys/Colombia/`x'") pattern(*Vivienda y Hogares*)
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
filelist , dir("$hf_input/Household Surveys/Colombia/") pattern(*Vivienda y Hogares*)
// norecur
gen fullname = dirname + "/" + filename
keep fullname
gen ext = substr(fullname, length(fullname)-2, 3)
keep if ext == "dta" | ext == "txt"
levelsof fullname, local(files_toloop)

// convert the files in the directory to be DTA files:
foreach file in `files_toloop' {
	di "`file'"
	// if the file is a txt file, save it as a DTA file
	// here, dollar sign indicates the end of the string
	if (regexm("`file'", ".txt$")) {
		import delimited using "`file'", clear //bindquote(strict)
 		local file = regexr("`file'", ".txt$", "")
		gen file_name = "`file'"
		di "`file'.dta"
		save "`file'.dta", replace
	}

	// If the file is already a DTA file, save a column indicating the file location.
	// And, rename all the variables to be lower case.
	if (regexm("`file'", ".dta$")) {
		use "`file'", clear
		gen file_name = "`file'"
		rename *, lower
		save "`file'", replace
	}
}


// Append all the Vivienda y Hogares files by year: ----------------------------

foreach x of numlist 2013/2021 {
	filelist , dir("$hf_input/Household Surveys/Colombia/`x'") pattern(*Vivienda y Hogares*dta)
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
	save "$hf_input/`x'appended.dta", replace
}


// Clean the resulting appended files -----------------------------------------

foreach x of numlist 2013/2021 {
	use "C:/Users/user/Dropbox/CGD GlobalSat/HF_measures/input/`x'appended.dta", clear
	
	// use the file extension to create strings that portray the year, month, 
	// and city type:
	replace file_name = subinstr(file_name, "//", "/",.)
	replace file_name = subinstr(file_name, "//", "/",.)
	drop if file_name == ""
	drop fullname
	drop ext
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
	gen city_type = substr(file_name, x3+1, length(file_name))
	replace city_type = subinstr(city_type, " - Vivienda y Hogares", "",.)
	replace city_type = subinstr(city_type, ".dta", "",.)
	drop x1 x2 x3 file_name

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

	// save file
	save "$hf_input/colombia`x'cleaned.dta", replace
}

// append all the years
use "$hf_input/colombia2020cleaned.dta", clear
foreach x of numlist 2013/2019 2021 {
	append using "$hf_input/colombia`x'cleaned.dta", force
}
save "$hf_input/cleaned_colombia_full.dta", replace

// convert to have Spanish accents
clear
cd "$hf_input"
unicode analyze cleaned_colombia_full.dta
unicode encoding set "latin1"
unicode translate cleaned_colombia_full.dta
use cleaned_colombia_full.dta

// Perform checks -----------------------------------------

// directorio == household ID
// fex == weights
// there should be no missing IDs in each dataset
gen check = missing(directorio)
assert(check == 0)
drop check

gen check = missing(fex_c_2011)
assert(check == 0)
drop check

// there should be no missing departamento
gen check = missing(dpto)
assert(check == 0)
drop check

// there should be no duplicated IDs in each dataset
sort year month directorio
quietly by year month directorio:  gen dup = cond(_N==1,0,_n)

// across each year, each column should have similar percent missing values
use cleaned_colombia_full.dta, clear
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
// TO DO -----------------------------------------------------------------
// 2013 is missing ~2% of the for variables once BEFORE "p4010", up to "p4030s4a1"
// the txt ones are missing for regis, clase, mes, area
// the dta ones are missing p6006

// there should be no error messages coming from STATA that you don't understand
// all months and years should be represented
// within each month and year, there should be no missing datasets
// within each month and year, there should be relative continuity of the LEVELs of the variable
// all months and years should have 3 parts: from Area, Cabecera, and Surroundings

// CHECK IF IT HAS SOMETHING TO DO WITH STRING VS. NUMERIC

// TO DO -----------------------------------------------------------------

// how is it possible that a person can be both in Cabecera and Resto?
drop if city_type == "╡rea"


// make sure that I have every month for every year available:


// keep the variables pertaining to wealth (TV, etc.)


// keep the variables pertaining to unique ID variables & survey weights (FEX -- factor de expansion)


// create a column with the year and month
// append all the data together
// make sure that we can replicate colombia's unemployment numbers













br




display c(current_time)
log close
exit, clear





// Interpreting the Colombian dataset:
//
//https://catalog.ihsn.org/index.php/catalog/7000/data-dictionary/F1?file_name=%C3%81rea%20-%20Caracter%C3%ADsticas%20generales%20(Personas)
// merge with geographic data
// --> dpto (departamento) is geographic data:
// http://microdatos.dane.gov.co/index.php/catalog/456/datafile/F39
// Departamento
// 05 Antioquia
// 08 Atlantico
// 11 Bogota D.C
// 13 Bolivar
// 15 Boyaca
// 17 Caldas
// 18 Caqueta
// 19 Cauca
// 20 Cesar
// 23 Cordoba
// 25 Cundinamarca
// 27 Choco
// 41 Huila
// 44 La guajira
// 47 Magdalena
// 50 Meta
// 52 Narino
// 54 Norte de santander
// 63 Quindio
// 66 Risaralda
// 68 Santander
// 70 Sucre
// 73 Tolima
// 76 Valle del cauca
// 81 Arauca
// 85 Casanare
// 86 Putumayo
// 88 Departamento archipielago de san andres, providencia y santa Catalina
// 91 Amazonas

































