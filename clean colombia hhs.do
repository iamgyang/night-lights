// This file attempts to clean some of the household survey datasets 
// from Colombia.

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

// Convert files to have Spanish Accents --------------------------------------
	
// get all the file names from a directory
filelist , dir("$hf_input/Household Surveys/Colombia/") pattern(*.dta) norecur
gen fullname = dirname + "/" + filename
keep fullname
levelsof fullname, local(files_toloop)

// convert the files in the directory to have Spanish accents
foreach file in `files_toloop' {
	clear

	//	make all the accents appear in the STATA file:
	unicode analyze "`file'"
    unicode encoding set "latin1"
	unicode translate "`file'"
}

// Grab all the Vivienda y Hogares from the folder ----------------------------

// get all the file names from a directory
filelist , dir("$hf_input/Household Surveys/Colombia/") pattern(*Vivienda y Hogares*)
// norecur
gen fullname = dirname + "/" + filename
keep fullname
gen ext = substr(fullname, length(fullname)-2, 3)
keep if ext == "dta" | ext == "txt"
generate u1 = runiform()
sort u1
gen num = _n
keep if ext == "txt"
levelsof fullname, local(files_toloop)

// convert the files in the directory to be DTA files:
foreach file in `files_toloop' {
	di "`file'"
// if the file is a txt file, save it as a DTA file
// here, dollar sign indicates the end of the string
	if (regexm("`file'", ".txt$")) {
		import delimited using "`file'", clear //bindquote(strict)
 		local file = regexr("`file'", ".txt$", "")
// 		local file = lower("`file'")
		gen file_name = "`file'"
		di "`file'.dta"
		save "`file'.dta", replace
	}
// If the file is already a DTA file, save a column indicating the file location.
// And, rename all the variables to be lower case.
	if (strpos("`file'", "dta")) {
		import delimited using "`file'", clear
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
	levelsof fullname, local(files_toloop)
	foreach file in `files_toloop' {
		di "`file'"
		append using "`file'", force
	}
	save "$hf_input/Household Surveys/Colombia/`x'appended.dta", replace
}

// there should be no missing IDs in each dataset
// there should be <90% missing for almost all variables
// there should be no error messages coming from STATA that you don't understand
// all months and years should be represented
// within each month and year, there should be no missing datasets
// within each month and year, there should be relative continuity of the LEVELs of the variable
// all months and years should have 3 parts: from Area, Cabecera, and Surroundings

















// convert the files in the directory to be DTA files:
append using `:dir . files "*Vivienda y Hogares*dta"'
drop if file_name == ""
drop filename








append using "$hf_input/Household Surveys/Colombia/2014/Abril.txt/Abril.txt/`file'"
// make sure that I have every month for every year available:


// keep the variables pertaining to wealth (TV, etc.)


// keep the variables pertaining to unique ID variables & survey weights (FEX -- factor de expansion)

// directorio == household ID
// fex == weights

// create a column with the year and month
// append all the data together
// make sure that we can replicate colombia's unemployment numbers



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

































