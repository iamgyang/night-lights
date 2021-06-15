*** re-producing the storygard regressions under different methods of cleaning
*** the underlying negative night lights data

*** Produce datasets:
*** e.g.
*** 1. collapse by ADM2 quarter and drop if negative --> collapse to country-year
*** 2. collapse by country month and drop if negative --> collapse to country-year
*** 3. collapse by ADM2 quarter and drop if negative --> collapse to country-year
*** 4. collapse by country quarter and drop if negative --> collapse to country-year
*** 5. collapse by ADM2 month and drop if negative --> collapse to country-year
*** 6. collapse by country year and drop if negative --> collapse to country-year

*** For each of those 4 datasets:

*** Regress ln(ANNUAL GROWTH GDP) ~ ln(ANNUAL GROWTH sum lights) [w/ country and year fixed effects]
*** Regress ln(QUARTER GROWTH GDP) ~ ln(QUARTER GROWTH sum lights) [w/ country and year fixed effects]

*** Macros -----------------------------------------------------------------
	foreach user in "`c(username)'" {
		global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
		global hf_input "$root/HF_measures/input/"
		global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
	}

	global outreg_file_natl_yr "$hf_input/natl_reg_hender_21.xls"

	clear all
	set more off 
	
*** CHANGE THIS!! --- Do we want to install user-defined functions? --------
	loc install_user_defined_functions "No"
	
*** Install user-defined functions: ----------------------------------------
	if ("`install_user_defined_functions'" == "Yes") {
		foreach i in rangestat wbopendata kountry mmerge outreg2 somersd asgen moss {
			ssc install `i'
		}
	}

*** -----------------------------------------------
*** Produce NTL datasets that have negatives deleted at certain points:
*** -----------------------------------------------

use "$hf_input/all_NTL_data.dta", clear
gen month = substr(time, 1, 3)
keep iso3c gid_2 mean_pix sum_pix year quart month pol_area
save "$hf_input/base_NTL.dta", replace

foreach time_collapse in year quart month none {
foreach area_collapse in gid_2 iso3c none {
	use "$hf_input/base_NTL.dta", clear
	rename pol_area sum_area
	if ("`time_collapse'" != "none") & ("`area_collapse'" != "none") {
		drop if sum_pix <0
		collapse (sum) sum_area sum_pix, by(year `time_collapse' `area_collapse' iso3c)
	}
	collapse (sum) sum_pix sum_area, by(year iso3c)
	export delimited "$hf_input/`time_collapse'_`area_collapse'.csv", replace
}
}

*** -----------------------------------------------
*** Produce full merged GDP dataset, collapsed at annual level:
*** -----------------------------------------------

use "$hf_input/imf_pwt_oxf_ntl.dta", clear
keep iso3c year quarter rgdp ox_rgdp_lcu pwt_rgdpna imf_rgdp_lcu WDI 
rename (rgdp ox_rgdp_lcu pwt_rgdpna imf_rgdp_lcu) (IMF_quart Oxford PWT IMF_WEO)
collapse (sum) Oxford IMF_quart (mean) WDI PWT IMF_WEO, by(iso3c year)
replace Oxford = . if Oxford  == 0
replace IMF_quart = . if IMF_quart  == 0
sort iso3c year
save "$hf_input/natl_accounts_GDP_annual_all.dta", replace

*** -----------------------------------------------
*** For each of those datasets, run regressions:
*** -----------------------------------------------

foreach time_collapse in year quart month none {
foreach area_collapse in gid_2 iso3c none {
	import delimited "$hf_input/`time_collapse'_`area_collapse'.csv", clear
	sort iso3c year
	fillin iso3c year
	drop _fillin
	sort iso3c year
	mmerge iso3c year using "$hf_input/natl_accounts_GDP_annual_all.dta"
	replace sum_pix = sum_pix / sum_area
	label variable sum_pix "Sum pixels / Area"
	
	*** get logged variables:
		foreach var of varlist sum_pix Oxford IMF_quart PWT IMF_WEO WDI {
			sort iso3c year
			loc lab: variable label `var'
			gen log_delt_`var'_1 = ln(`var')
			label variable log_delt_`var'_1 "Log `lab'" 
		}
		
	***	make country and year fixed effects.
		encode iso3c, gen(iso3c_f)
		tostring year, replace
		encode year, gen(year_f)
		export delimited "$hf_input/merged_`time_collapse'_`area_collapse'.csv", replace
		
	*** Regressions on log(GDP)~log(NTL)
		foreach var of varlist Oxford IMF_quart PWT IMF_WEO WDI{
			regress log_delt_`var'_1 log_delt_sum_pix_1 i.year_f i.iso3c_f, robust
			outreg2 using "$outreg_file_natl_yr", append ///
			ctitle("`var'_OLS_`time_collapse'_`area_collapse'") ///
			label dec(4) keep (log_delt_sum_pix_1)
		}
		
	*** Perform the same regressions but using FE estimator. 
	*** Should have same coefficients.
		destring year, replace
		xtset iso3c_f year
		foreach var of varlist Oxford IMF_quart PWT IMF_WEO WDI{
			xtreg log_delt_`var'_1 log_delt_sum_pix_1 i.year_f, fe robust cluster(iso3c_f)
			outreg2 using "$outreg_file_natl_yr", append ///
			ctitle("`var'_FE_`time_collapse'_`area_collapse'") ///
			label dec(4) keep (log_delt_sum_pix_1)
		}
}
}


*** --------------------------------
*** Check if NTL aggregation downloaded online for PRIOR data is accurate
*** --------------------------------
	clear all
	set more off 
	
	global outreg_file_pre_2013 "$hf_input/natl_reg_hender_pre_2013_13.xls"
	
*** get the dataset of pixel AREA from our original NTL dataset
	import delimited "$hf_input/none_none.csv", clear
	bysort iso3c: egen median_sum_area = median(sum_area)
	collapse (firstnm) median_sum_area, by(iso3c)
	rename median_sum_area sum_area
	tempfile pixel_area
	save `pixel_area'

*** Import dataset
	import delimited "$hf_input/Nighttime_Lights_ADM2_1992_2013.csv", clear
	collapse (sum) sum_light, by(countrycode countryname year)
// 	rename (mean_light) (sum_light)
	
*** Merge with pixel area:
	rename countrycode iso3c
	mmerge iso3c using `pixel_area'
	keep if _m == 3
	drop _m
	
*** Merge w/ GDP measures:
	mmerge iso3c year using "$hf_input/natl_accounts_GDP_annual_all.dta"
	keep if _m == 3
	keep iso3c countryname year sum_light Oxford WDI sum_area
	rename sum_light sum_pix
	replace sum_pix = sum_pix / sum_area
	label variable sum_pix "Sum pixels / Area"
		
// 	export delimited "$hf_input/henderson.csv", replace
	
*** Get logged 1-yr growth variables:
		foreach var of varlist sum_pix Oxford WDI {
			sort iso3c year
			loc lab: variable label `var'
			by iso3c: gen `var'_L1 = `var'[_n-1] if year==year[_n-1]+1
			gen delt_`var'_1 = `var'/`var'_L1
			gen log_delt_`var'_1 = ln(delt_`var'_1)
			drop delt_`var'_1 `var'_L1
			label variable log_delt_`var'_1 "Log 1yr change in `lab'" 
		}
	br

*** get rid of post-2008
// 	keep if year <= 2008
	
***	Make country and year fixed effects.
	encode iso3c, gen(iso3c_f)
	tostring year, replace
	encode year, gen(year_f)

*** Regressions on log(1+%changeGDP)~log(1+%changeNTL)
	foreach var of varlist Oxford WDI{
		regress log_delt_`var'_1 log_delt_sum_pix_1 i.year_f i.iso3c_f, robust
		outreg2 using "$outreg_file_pre_2013", append ///
		ctitle("`var'_OLS_`time_collapse'_`area_collapse'") ///
		label dec(4) keep (log_delt_sum_pix_1)
	}
	
*** Perform the same regressions but using FE estimator. 
*** Should have same coefficients.
	destring year, replace
	xtset iso3c_f year
	foreach var of varlist Oxford WDI{
		xtreg log_delt_`var'_1 log_delt_sum_pix_1 i.year_f, fe robust
		outreg2 using "$outreg_file_pre_2013", append ///
		ctitle("`var'_FE_`time_collapse'_`area_collapse'") ///
		label dec(4) keep (log_delt_sum_pix_1)
	}
	
	






	
	
	
	
	
	
	
	
*** ----------------------------------------------------------------------
*** ----------------------------------------------------------------------
*** compare NTL from 2012-2013






import delimited "$hf_input/henderson_pre2013_ntl_wb_gdp.csv", clear
destring oxford ln_wbgdp ln_sumlight ln_ox, replace ignore(`"NA"', illegal) force
keep iso3c year ln_wbgdp ln_sumlight ln_ox
foreach var of varlist year ln_wbgdp ln_sumlight ln_ox {
	drop if `var' == .
}

encode iso3c, gen(iso3c_f)
tostring year, replace
encode year, gen(year_f)
destring year, replace


xtset iso3c_f year

xtreg ln_ox ln_sumlight i.year_f, fe robust






// ARCHIVE ==============================================================



import delimited "$hf_input/merged_none_none.csv", clear

drop iso3c_f
encode iso3c, gen(iso3c_f)
drop year_f
tostring year, replace
encode year, gen(year_f)

regress log_delt_oxford_1 log_delt_sum_pix_1 
avplot log_delt_sum_pix_1, mlabel(iso3c)

regress log_delt_imf_quart_1 log_delt_sum_pix_1 i.year_f i.iso3c_f
avplot log_delt_sum_pix_1, mlabel(iso3c)

regress log_delt_wdi_1 log_delt_sum_pix_1 i.year_f i.iso3c_f
avplot log_delt_sum_pix_1, mlabel(iso3c)









exit


xtset iso3c_f year
xtreg  log_delt_Oxford_1   log_delt_sum_pix_1     i.year, fe
estimates store fixed_year_cont
xtreg  log_delt_Oxford_1   log_delt_sum_pix_1     i.year_f, fe
estimates store fixed_year_dum
xtreg  log_delt_Oxford_1   log_delt_sum_pix_1     i.iso3c_f, fe
estimates store fixed_country_dum
regress log_delt_Oxford_1   log_delt_sum_pix_1     i.iso3c_f     
estimates store ols_indiv
regress log_delt_Oxford_1 log_delt_sum_pix_1 i.iso3c_f , cluster(iso3c_f)
estimates store ols_indiv_TEST
regress log_delt_Oxford_1   log_delt_sum_pix_1     i.iso3c_f     i.year_f
estimates store ols
areg log_delt_Oxford_1   log_delt_sum_pix_1 i.iso3c_f, absorb(year_f)
estimates store areg
estimates table fixed_year_cont fixed_year_dum fixed_country_dum ols_indiv ols_indiv_TEST ols areg, star stats(N r2 r2_a)

*** -----------------------------------------------
*** Check with Parth's data in R:
*** -----------------------------------------------

use "$hf_input/GDP_ntl_neg.dta", clear

br iso3c year sum_pix_month_gid_2 sum_sumlight_rmvad2 if ///
abs(sum_sumlight_rmvad2 - sum_pix_month_gid_2) > 2

*** get area growths:
	gen ntl_p = (sum_sumlight_rmvad2 / sum_area)
	gen ntl_g = (sum_pix_month_gid_2 / sum_area)
	
*** get logged 1-yr growth variables:
	foreach var of varlist ntl_p ntl_g Oxford IMF_quart PWT IMF_WEO {
		sort iso3c year
		loc lab: variable label `var'
		by iso3c: gen `var'_L1 = `var'[_n-1] if year==year[_n-1]+1
		gen delt_`var'_1 = `var'/`var'_L1
		gen log_delt_`var'_1 = ln(delt_`var'_1)
		drop delt_`var'_1 `var'_L1
		label variable log_delt_`var'_1 "Log 1yr change in `lab'" 
	}
	
*** create categorical variables:
	encode iso3c, gen(iso3c_f)
	tostring year, replace
	encode year, gen(year_f)

*** get squared term for log:
	rename log_delt_ntl_g_1 log_delt_sum_pix_1
	gen sq_log_delt_sum_pix_1 = (log_delt_sum_pix_1)^2

*** aesthetics: labeling:
	label variable log_delt_sum_pix_1 "Log(Annual Change in Sum Pixels)"
	label variable sq_log_delt_sum_pix_1 "Log(Annual Change in Sum Pixels)^2"
	
global outreg_file_story_fe "$hf_input/outreg_file_story_fe_7.xls"
foreach var of varlist Oxford IMF_quart PWT IMF_WEO {
		regress   log_delt_`var'_1   log_delt_sum_pix_1 sq_log_delt_sum_pix_1 sq_log_delt_sum_pix_1 ///
		i.iso3c_f i.year_f, robust
		outreg2 using "$outreg_file_story_fe", append ctitle(`var') ///
		label dec(4) keep (log_delt_sum_pix_1 sq_log_delt_sum_pix_1)
	}






















