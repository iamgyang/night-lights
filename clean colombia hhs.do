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
	
	cls

*** Take a look at rental payments -----------------------------------------
cd "$hf_input/Household Surveys/Colombia/2020/Septiembre.dta/Septiembre.dta"

// get all the file names from a directory
filelist , dir("$hf_input/Household Surveys/Colombia/2020/Septiembre.dta/Septiembre.dta") pattern(*.dta) norecur
keep filename
levelsof filename, local(files_toloop)

// create a 
// tempfile variables2
// 	gen name = ""
// 	gen type = ""
// 	gen varlab = ""
// 	gen location = ""
// 	save `variables2'
// clear

// convert the files in the directory to have Spanish accents
foreach file in `files_toloop' {
	clear

	//	make all the accents appear in the STATA file:
	unicode analyze "`file'"
    unicode encoding set "latin1"
	unicode translate "`file'"

// 	// 	get the variables2 from the file and append
// 	use "`file'", clear
// 	desc, replace
// 	keep name type varlab
// 	gen location = "`file'"
// 	append using `variables2'
// 	save `variables2', replace
}
// clear
//
// use `variables2'
// drop filename
// drop if location == ""
// export excel using "C:\Users\user\Dropbox\CGD GlobalSat\HF_measures\input\Household Surveys\Colombia\2020_september_all_variables.xlsx", firstrow(varlabels) replace

// get the overall survey
cd "C:\Users\user\Dropbox\CGD GlobalSat\HF_measures\input\Household Surveys\Colombia\2020\Septiembre.dta\Septiembre.dta"
use "╡rea - Características generales (Personas).dta", clear

br if DIRECTORIO == 5214255 & ORDEN == 1

	preserve
	sort DIRECTORIO ORDEN
	keep DIRECTORIO ORDEN
	duplicates tag DIRECTORIO ORDEN, gen (dup_id_cov)
	br if dup_id_cov == 1
	assert dup_id_cov==0
	restore











