// Macros
	foreach user in "`c(username)'" {
		global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
		global hf_input "$root/HF_measures/input/"
		global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
	}
	
	global outreg_file_city "$hf_input/city_reg_1.xls"

clear all
set more off 

use "$hf_input/city_ntl_merge_wide_sum_pix.dta", clear
use "$hf_input/city_ntl_merge_wide_mean_pix.dta", clear

// Log every variable
	foreach var of varlist delt* {
		replace `var' = ln(1+`var')
	}

	
// Regress change in GDP per capita with change in pixels across ALL months
	regress delt_*2016 delt_*pix_2016*, robust
		outreg2 using "$outreg_file_city", append ctitle("All mo. 2014-2016") ///
			label dec(3)
	regress delt_*2014 delt_*pix_2014*, robust
		outreg2 using "$outreg_file_city", append ctitle("All mo. 2013-2014") ///
			label dec(3)

// Since we have some months consistantly being absent, missing varialbes will mess 
// with regression estimates. So, fit individual associations w/ change in gdppc.
	foreach i of num 1/12 {
		regress delt_gdppc2016 delt_*pix_2016_`i', robust    
		outreg2 using "$outreg_file_city", append ctitle("mo. `i' 2014-16") ///
			label dec(3)
	}
	foreach i of num 1/12 {
		regress delt_gdppc2014 delt_*pix_2014_`i', robust    
		outreg2 using "$outreg_file_city", append ctitle("mo. `i' 2013-14") ///
			label dec(3)
	}