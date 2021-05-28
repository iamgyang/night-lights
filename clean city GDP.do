// Macros
	foreach user in "`c(username)'" {
		global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
		global hf_input "$root/HF_measures/input/"
		global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
	}
	
clear all
set more off 

// ssc install:
	// rangestat
	// wbopendata
	// kountry
	// mmerge
	// outreg2
	// somersd
	
//Import city-level Indonesia GDP dataset
	clear
	import excel "$hf_input/National Accounts\indonesia_city_gdp_2018_2019.xlsx", ///
		sheet("Sheet1") firstrow
	tempfile yr1
	save `yr1'
	clear
	import excel "$hf_input/National Accounts\indonesia_city_gdp_2018_2019.xlsx", ///
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
		"$hf_input/National Accounts/cleaned_indonesia_city_gdp_2018_2019.csv", ///
		replace


























































