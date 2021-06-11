*** Macros -----------------------------------------------------------------
	foreach user in "`c(username)'" {
		global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
		global hf_input "$root/HF_measures/input/"
		global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
	}

	global outreg_file_natl_yr "$hf_input/natl_reg_8.xls"
	global outreg_file_natl_quart "$hf_input/natl_reg_1.xls"

	clear all
	set more off 

*** Import PWT -------------------------------------------------------------
	use "$hf_input/National Accounts/pwt100.dta", clear
	keep rgdpna year countrycode
	drop if rgdpna == . 
	drop if year < 2012
	rename countrycode iso3c
	tempfile pwt
	save `pwt'

*** Import NTL -------------------------------------------------------------
	use "$hf_input/ntl_natl_gdp.dta", clear

*** Collapse NTL by ISO3c and year (taking a mean for ISO3C and a sum for year)
	collapse (mean) mean_pix1 sd_pix1 sum_pix_sum sum_pix_mean, by (year iso3c)

*** Merge NTL and PWT by ISO3c.
	mmerge iso3c year using `pwt'
	keep if _m==3
	drop _m

*** TO DO:: SEE W/ WDI GDP??

*** Create 1yr and 5yr (2012-2020) lagged variable for PWT and NTL. 
	foreach var of varlist mean_pix1 sd_pix1 sum_pix_sum sum_pix_mean rgdpna {
		sort iso3c year
		loc lab: variable label `var'
		
		by iso3c: gen `var'_L1 = `var'[_n-1] if year==year[_n-1]+1
		gen delt_`var'_1 = `var'/`var'_L1
		gen log_delt_`var'_1 = ln(delt_`var'_1)
		drop delt_`var'_1 `var'_L1
		label variable log_delt_`var'_1 "Log change in `lab' 1yr"
		
		sort iso3c year
		by iso3c: gen `var'_L4 = `var'[_n-4] if year==year[_n-4]+4
		gen delt_`var'_4 = `var'/`var'_L4
		gen log_delt_`var'_4 = ln(delt_`var'_4)
		drop delt_`var'_4 `var'_L4
		label variable log_delt_`var'_4 "Log change in `lab' 4yr"
	}

***	Make country fixed effects.
	encode iso3c, gen(iso3c_factor)

*** Plot first differences.
	twoway (scatter log_delt_rgdpna_4 log_delt_sum_pix_sum_4)
	twoway (scatter log_delt_rgdpna_1 log_delt_sum_pix_sum_1)
	twoway (scatter log_delt_rgdpna_4 log_delt_mean_pix1_4)
	twoway (scatter log_delt_rgdpna_1 log_delt_mean_pix1_1)
	
*** Run regression of log(1+changePWT)~log(1+changeNTL)
*** Run regression of log(1+changePWT)~log(1+changeNTL) + country fixed effects
	qui regress log_delt_rgdpna_4 log_delt_sum_pix_sum_4 i.iso3c_factor, robust
		outreg2 using "$outreg_file_natl_yr", append ctitle("4yr") ///
		label dec(4) keep (log_delt_sum_pix_sum_4) ///
		addtext(Country FE, YES)
	qui regress log_delt_rgdpna_1 log_delt_sum_pix_sum_1 i.iso3c_factor, robust
		outreg2 using "$outreg_file_natl_yr", append ctitle("1yr") ///
		label dec(4) keep (log_delt_sum_pix_sum_1) ///
		addtext(Country FE, YES)
	qui regress log_delt_rgdpna_4 log_delt_mean_pix1_4 i.iso3c_factor, robust
		outreg2 using "$outreg_file_natl_yr", append ctitle("4yr") ///
		label dec(4) keep (log_delt_mean_pix1_4) ///
		addtext(Country FE, YES)
	qui regress log_delt_rgdpna_1 log_delt_mean_pix1_1 i.iso3c_factor, robust
		outreg2 using "$outreg_file_natl_yr", append ctitle("1yr") ///
		label dec(4) keep (log_delt_mean_pix1_1) ///
		addtext(Country FE, YES)
	qui regress log_delt_rgdpna_4 log_delt_sum_pix_sum_4, robust
		outreg2 using "$outreg_file_natl_yr", append ctitle("4yr") ///
		label dec(4) keep (log_delt_sum_pix_sum_4) ///
		addtext(Country FE, NO)
	qui regress log_delt_rgdpna_1 log_delt_sum_pix_sum_1, robust
		outreg2 using "$outreg_file_natl_yr", append ctitle("1yr") ///
		label dec(4) keep (log_delt_sum_pix_sum_1) ///
		addtext(Country FE, NO)
	qui regress log_delt_rgdpna_4 log_delt_mean_pix1_4, robust
		outreg2 using "$outreg_file_natl_yr", append ctitle("4yr") ///
		label dec(4) keep (log_delt_mean_pix1_4) ///
		addtext(Country FE, NO)
	qui regress log_delt_rgdpna_1 log_delt_mean_pix1_1, robust
		outreg2 using "$outreg_file_natl_yr", append ctitle("1yr") ///
		label dec(4) keep (log_delt_mean_pix1_1) ///
		addtext(Country FE, NO)




*** 
*** 
*** 
*** 
*** 
*** 
*** 
*** 
***
*** 
*** 
*** 
*** 
***
*** 
*** 
*** 
*** 
*** 
*** 
*** 
*** 
*** 
*** 
*** 
*** 
*** 
*** 
*** 
*** 
*** 
*** 
*** 
*** 
