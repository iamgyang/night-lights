// Macros
	foreach user in "`c(username)'" {
		global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
		global hf_input "$root/HF_measures/input/"
		global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
	}

global outreg_file "$hf_input/prelim_reg_7.xls"
global import_nightlights "yes"
	
clear all
set more off 

// ssc install:
	// rangestat
	// wbopendata
	// kountry
	// mmerge
	// outreg2
	// somersd
	// 	asgen
	
//Import IMF dataset
	import excel "$hf_input/National Accounts/imf_national_gdp.xlsx", ///
	sheet("Nominal Quarterly") cellrange(B7:AH85) clear

// replace first row to be the variable names
	foreach var of varlist * {
	  replace `var' = "" if `var'=="..."
	  rename `var' `=strtoname("x"+`var'[1])'
	  
	}

// drop 1st row
	drop in 1
	destring x*, replace

//rename everything to lower
	rename *, lower
	rename xcountry country

// get iso3c codes:
	kountry country, from(other) stuck
	ren(_ISO3N_) (temp)
	kountry temp, from(iso3n) to(iso3c)
	ren (_ISO3C_) (iso3c)
	replace iso3c = "ARM" if country == "Armenia, Rep. of"
	replace iso3c = "AZE" if country == "Azerbaijan, Rep. of"
	replace iso3c = "BLR" if country == "Belarus, Rep. of"
	replace iso3c = "HKG" if country == "China, P.R.: Hong Kong"
	replace iso3c = "HRV" if country == "Croatia, Rep. of"
	replace iso3c = "EST" if country == "Estonia, Rep. of"
	replace iso3c = "XKX" if country == "Kosovo, Rep. of"
	replace iso3c = "MDA" if country == "Moldova, Rep. of"
	replace iso3c = "MKD" if country == "North Macedonia, Republic of"
	replace iso3c = "POL" if country == "Poland, Rep. of"
	replace iso3c = "SRB" if country == "Serbia, Rep. of"
	replace iso3c = "SVK" if country == "Slovak Rep."
	replace iso3c = "SVN" if country == "Slovenia, Rep. of"
	drop temp
	
//	wide to long:
	reshape long x, i(country iso3c) j(year_quarter, string)
	drop if country == "Euro Area"
	drop if x == .
	rename x nom_gdp
	gen  yq = quarterly(year_quarter, "YQ")
	format yq %tq
	drop year_quarter
	gen year = yofd(dofq(yq))
	tempfile quarterly_nominal_gdp
	save `quarterly_nominal_gdp'
	
// Convert from nominal to real GDP

// get GDP deflator data:
	wbopendata, language(en – English) indicator(NY.GDP.DEFL.ZS) long clear
	keep countrycode year ny_gdp_defl_zs
	drop if ny_gdp_defl_zs ==.
	rename (countrycode ny_gdp_defl_zs) (iso3c deflator)
	mmerge iso3c year using `quarterly_nominal_gdp'
	keep if inlist(_m, 2,3)
	
// make the base year 2016: (won't really make a difference if all we do is 
// growth regressions, but if we do something else, want to have this comparable)
	bysort iso3c: egen min_yr = min(year)
	bysort iso3c: egen max_yr = max(year)
	egen inf_yr = max(min_yr)
	egen sup_yr = min(max_yr)
	tab inf_yr sup_yr 
	desc sup_yr 
	
	gen denom = deflator if year == 2016
	by iso3c: egen deflator_2 = max(denom)
	gen deflator_3 = deflator / deflator_2 * 100
	keep iso3c nom_gdp yq deflator_3
	sort iso3c yq
	gen rgdp = nom_gdp / deflator_3
	drop deflator_3

// done with cleaning GDP data:
	save "$hf_input/imf_real_gdp.dta", replace
	
// import NTL:

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
		use "$hf_input/NTL_appended.dta", clear
	}

// save
	save "$hf_input/NTL_appended.dta", replace
	use "$hf_input/NTL_appended.dta", clear
	
// merge w/ GDP data
	replace std_pix = "" if std_pix == "NA"
	destring(std_pix), generate(sd_pix)

	save "$hf_input/NTL_appended.dta", replace
	use "$hf_input/NTL_appended.dta", clear
	
// First, we aggregate by taking a mean (or sum) across the ADM2's (space).
	bysort iso3c time: asgen mean_pix1 = mean_pix, w(pol_area)
	bysort iso3c time: asgen sd_pix1 = sd_pix, w(pol_area)
	bysort iso3c time: egen sum_pix_sum = total(sum_pix)
	bysort iso3c time: asgen sum_pix_mean = sum_pix, w(pol_area)

// Second, we aggregate by taking a mean across the quarters (time):
	collapse (mean) mean_pix1 sd_pix1 sum_pix_sum sum_pix_mean, by (iso3c yq)
	br

// merge with real GDP:
	mmerge iso3c yq using "$hf_input/imf_real_gdp.dta"
	keep if inlist(_m, 3)
	sort iso3c yq
	drop _m
	
// label vars:
	label variable iso3c "ISO3 national code"
	label variable yq "quarterly date"
	label variable mean_pix1 "mean pixel luminance, weighted by polygon size"
	label variable ///
	sum_pix_mean "sum of pixel luminance: collapsed with a mean across TIME (months), and a MEAN across LOCATION (ADM2s)"
	label variable ///
	sum_pix_sum "sum of pixel luminance: collapsed with a mean across TIME (months), and a SUM across LOCATION (ADM2s)"
	label variable ///
	sum_pix_sum "mean of the sum of pixel luminance, weighted by polygon size"
	label variable sd_pix1 ///
	"mean of the standard deviation of pixel luminance, weighted by polygon size"
	label variable rgdp "quarterly real GDP in local currency"
	label variable nom_gdp "quarterly nominal GDP in local currency"
	
// create year and quarter variables for R users:
	gen year = yofd(dofq(yq))
	gen quarter = quarter(dofq(yq))	
	
// save:
	save "$hf_input/ntl_natl_gdp.dta", replace
	
// prep for regressions:
	// get factor variables for country code and quarter:
		encode iso3c, gen(iso3c_factor)
		gen quarter = quarter(dofm(yq))
		tostring quarter, generate(quarter_factor)
		encode quarter_factor, gen(quarter_factor_1)
		label variable quarter_factor_1 "quarter"
		
	// logged quarterly change in luminance and GDP:
		foreach var of varlist mean_pix rgdp nom_gdp {
			sort iso3c yq
			loc lab: variable label `var'
			
			by iso3c: gen `var'_L1 = `var'[_n-1] if yq==yq[_n-1]+1
			gen delt_`var' = `var'/`var'_L1
			gen log_delt_`var' = ln(delt_`var')
			drop delt_`var' `var'_L1
			
			label variable log_delt_`var' "Log change in `lab'"
		}

// preliminary regression:
	qui regress log_delt_rgdp log_delt_mean_pix i.iso3c_factor, robust
		outreg2 using "$outreg_file", append ctitle("real") ///
		label dec(3) keep (log_delt_mean_pix) ///
		addtext(Country FE, YES, Quarter FE, NO)
	qui regress log_delt_nom_gdp log_delt_mean_pix i.iso3c_factor, robust
		outreg2 using "$outreg_file", append ctitle("nominal") ///
		label dec(3) keep(log_delt_mean_pix) ///
		addtext(Country FE, YES, Quarter FE, NO)
	qui regress log_delt_rgdp log_delt_mean_pix i.iso3c_factor ///
	i.quarter_factor_1, robust
		outreg2 using "$outreg_file", append ctitle("real") ///
		label dec(3) keep(log_delt_mean_pix) ///
		addtext(Country FE, YES, Quarter FE, YES)
	
// Robustness
	// confused as to this negative slope. test if negative slope is due to certain
	// outliers/regression assupmtion problems:
		regress log_delt_nom_gdp log_delt_mean_pix i.iso3c_factor ///
		i.quarter_factor_1
	// heteroskedasticity
		estat hettest
	// normality of residuals
		predict r, resid
		kdensity r, normal
		pnorm r
		qnorm r
		rvfplot, yline(0)
	// added variable plot
		avplot log_delt_mean_pix
	// Theil Sen estimator
		censlope log_delt_nom_gdp log_delt_mean_pix		
		
		
// ARCHIVE========

// Bit dissapointing results

// // get GDP PPP conversion data:
// 	wbopendata, language(en – English) indicator(PA.NUS.PPP) long clear
// 	keep countrycode year pa_nus_ppp
// 	drop if pa_nus_ppp ==.
// 	rename (countrycode pa_nus_ppp) (iso3c ppp_defl)
// 	mmerge iso3c year using `quarterly_nominal_gdp'
// 	keep if inlist(_m, 2,3)
//
// // GDP, PPP from local nominal currency units
//	
//	












