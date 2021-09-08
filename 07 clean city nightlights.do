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

// ========================================================================

// merge the ADM codes with the actual lat-long data
	import delimited ///
		"$raw_data/National Accounts/city_ADM_bridge.csv", colrange(2) clear 
	tempfile adm_codes
	save `adm_codes', replace

	import delimited ///
		"$raw_data/National Accounts/oxford_city_data_lat_long.csv", clear 
	replace country = "USA" if country == "United States"
	rename (deltgdppc deltgddpc) (delt_gdppc_1 delt_gdppc_2)
	replace delt_gdppc_1 = delt_gdppc_2 if delt_gdppc_1==. 
	drop delt_gdppc_2
	rename delt_gdppc_1 delt_gdppc
	mmerge metro country using `adm_codes'
	
// 	13 cities were not matched because they lied on the EDGE of an object ID polygon
	keep if _m == 3
	drop _m
	save "$input/city_ntl_merge_long.dta", replace
	
// merge with the night light data
	use "$input/NTL_appended.dta", clear
	keep objectid iso3c name_0 gid_1 name_1 gid_2 mean_pix sum_pix std_pix pol_area yq date2
	rename iso3c GID_0

	gen year = yofd(dofq(yq))
	gen mo = month(date2)
	
// We create a dataset of the CHANGE in the sum of night lights from 2013-14 and 
// 2014-2016 (the years we have city GDP change available).
	sort gid_2 mo year
	keep objectid sum_pix mean_pix year mo
	
// 	make sure we have 4 years (2013-2016 for each object ID)
	bysort objectid: gen length_check = _N 
	assert length_check == 105
	drop length_check
	
	tempfile ntl_app
	save `ntl_app'
	
// 	get the change in sum of pixel by object ID and year
	foreach func_var of varlist mean_pix sum_pix {
		clear 
		use `ntl_app'
		sort objectid mo year 
		by objectid mo: gen lag1_pix = `func_var'[_n-1]
		keep if inlist(year, 2013, 2014, 2015, 2016)
		gen delt_`func_var' = `func_var' / lag1_pix -1
		drop `func_var' lag1_pix
		drop if delt_`func_var' ==.
		
	//  now we have a dataset of annual change in nightlights (but, we have it
	//  for different months) the 'year' variable thus far has been referring
	//  to the END year of the change in nightlights (i.e. year 2013 refers to
	//  the change in NL from 2012-2013). 
		rename year yrend
		
	//  So, the change in NL from 2014-2016 should equal 2015 * 2016 change in NTL
		gen one_delt = delt + 1
		bysort objectid mo: gen lag_one_delt = one_delt[_n-1]
		replace delt_`func_var' = one_delt*lag_one_delt-1 if yrend == 2016
		drop one_delt lag_one_delt
		drop if yrend == 2015
		save "$input/annual_change_ntl_long_`func_var'.dta", replace

	//	merge the datasets:
		mmerge objectid yrend using "$hf_input/city_ntl_merge_long.dta"
		assert inlist(_m, 1, 3)
		keep if _m == 3
		
		keep objectid metro country delt* gid_0 gid_1 gid_2 yrend mo
		save "$input/city_ntl_merge_long_`func_var'.dta", replace
		use "$input/city_ntl_merge_long_`func_var'.dta", clear
		
	//  Now that we have the full dataset in long format, we'd like to turn it
	//  into wide format so that we can do some regressions on it. For the
	//  change in GDP per capita, we have the delt_gdppc variable, which is
	//  defined for years only. For the change in night lights pixels, we have
	//  the delt_sumpix variable, which is defined for a year and month. This
	//  means that we first reshape wide for one variable and then we do
	//  it again for the next, while merging at the end.
		tostring(yrend mo), gen (yr mon)
		drop yrend mo
		gen yrmo = "_" + yr + "_" + mon
		
		preserve
		keep delt_* objectid yrmo gid_0
		drop delt_gdppc
		reshape wide delt_`func_var', i(objectid gid_0) j(yrmo, string)
		tempfile ntl_`func_var'_wide
		save `ntl_`func_var'_wide'
		
		restore 
		keep delt_* objectid yr gid_0
		drop delt_`func_var'
		duplicates drop
		reshape wide delt_gdppc, i(objectid gid_0) j(yr, string)
		mmerge objectid using `ntl_`func_var'_wide'
		assert _m == 3
		drop _m
		
		save "$input/city_ntl_merge_wide_`func_var'.dta", replace

	}







