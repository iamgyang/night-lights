cls
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

*** Macros -----------------------------------------------------------------
	foreach user in "`c(username)'" {
		global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
		global hf_input "$root/HF_measures/input/"
		global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
	}

	global outreg_file_natl_yr "$hf_input/natl_reg_hender_28.xls"
	global outreg_file_compare_12_13 "$hf_input/outreg_file_compare_2012_2013_v2.xls"
	
	clear all
	set more off 
	
*** ------------------------------------------------------------------------
*** Produce NTL datasets that have negatives deleted at certain points:
*** ------------------------------------------------------------------------


// to fix: below data (call it nlgdad2) merged with Oxford on QUARTER-ISO3C. other data from clean natl GDP measures (neg_rem) merged with oxford on ANNUAL-ISO3C. Night lights are missing 2012 Q1 data. So, since Oxford was aggregated / collapsed AFTER merging--for nlgdad2, Oxford doesn't have Q1 stuff. On the other hand, for neg_rem, since Oxford was first aggregated on a year-level prior to merging, it included the entire 2012 year of GDP. 

	use "$hf_input/NTL_GDP_month_ADM2.dta", clear
	keep iso3c gid_2 mean_pix sum_pix year quarter month pol_area pwt_rgdpna ///
	imf_rgdp_lcu WDI imf_quart_nom_gdp imf_quart_rgdp ox_rgdp_lcu

// Drop negative values at the month-ADM2 level
	drop if sum_pix < 0

// Collapse to a year-quarter level, taking a mean of GDP values
	collapse (sum) sum_area sum_pix (mean) pwt_rgdpna imf_rgdp_lcu WDI ///
	imf_quart_rgdp ox_rgdp_lcu, by(year quarter iso3c)

// Collapse to a year level, taking a sum of GDP values
	collapse (sum) sum_area sum_pix ox_rgdp_lcu imf_quart_rgdp ///
	(mean) pwt_rgdpna imf_rgdp_lcu WDI, by(year iso3c)

// Rename the GDP variables
	rename (ox_rgdp_lcu imf_quart_rgdp pwt_rgdpna imf_rgdp_lcu WDI) (Oxford IMF_quart PWT IMF_WEO WDI)

// Since collapsing by sum inserts 0s if all the summed values were missing, 
// replace summed quarterly (now annual) GDP values with missing if they're 0
	replace Oxford = . if Oxford  == 0
	replace IMF_quart = . if IMF_quart  == 0

*** Make sure that we still have unique IDs across ISO3C and year:
	drop _m
	duplicates tag iso3c year, gen(dup)
	assert dup == 0
	drop dup
	
*** Merge with electricity data:
	mmerge year iso3c using "$hf_input/electricity.dta"

*** Make sure that we still have unique IDs across ISO3C and year:
	drop _m
	duplicates tag iso3c year, gen(dup)
	assert dup == 0
	drop dup
	sort iso3c year

	save "$hf_input/natl_accounts_GDP_annual_all.dta", replace

	

*** -----------------------------------------------
*** Run regressions:
*** -----------------------------------------------

foreach time_collapse in month none { //year quarter 
foreach area_collapse in gid_2 none { //iso3c 
		
		import delimited "$hf_input/`time_collapse'_`area_collapse'.csv", clear
		sort iso3c year
		fillin iso3c year
		drop _fillin
		
	*** make sure we don't have duplicate IDs (year-iso3c)
		duplicates tag year iso3c, gen(dup_tag)
		assert dup_tag == 0
		drop dup_tag
		sort iso3c year
		
	*** merge with GDP and electricity data:
		mmerge year iso3c using "$hf_input/natl_accounts_GDP_annual_all.dta"
		drop _m
		
	*** make sure we don't have duplicate IDs (year-iso3c)
		duplicates tag year iso3c, gen(dup_tag)
		assert dup_tag == 0
		drop dup_tag
		sort iso3c year
	
	*** replace sum pixels with sum pixels divided by area.
		replace sum_pix = sum_pix / sum_area
		label variable sum_pix "Sum pixels / Area"
		
	*** get logged variables:
		foreach var of varlist sum_pix Oxford IMF_quart PWT IMF_WEO WDI {
			sort iso3c year
			loc lab: variable label `var'
			gen log_`var' = ln(`var')
			label variable log_`var' "Log `lab'" 
		}
		
	***	make country and year fixed effects.
		encode iso3c, gen(iso3c_f)
		tostring year, replace
		encode year, gen(year_f)
		export delimited "$hf_input/merged_`time_collapse'_`area_collapse'.csv", ///
		replace
		
	*** Perform the same regressions but using FE estimator. 
	*** Should have same coefficients.
		destring year, replace
		xtset iso3c_f year
		foreach var of varlist Oxford IMF_quart PWT IMF_WEO WDI{
			
			*** night-lights XTREG
				xtreg log_`var' log_sum_pix i.year_f, fe robust ///
				cluster(iso3c_f)
				
				outreg2 using "$outreg_file_natl_yr", append ///
				ctitle("`var'_FE_`time_collapse'_`area_collapse'") ///
				label dec(4) keep (log_sum_pix) ///
				bdec(3) addstat(Between R-squared, e(r2_b), ///
				Within R-squared, e(r2_w), ///
				Overall R-squared, e(r2_o))
				
			*** night-lights REGHDFE
				reghdfe log_`var' log_sum_pix, absorb(iso3c_f year_f) ///
				vce(cluster iso3c_f)
				
				outreg2 using "$outreg_file_natl_yr", append ///
				ctitle("`var'_REGHDFE_`time_collapse'_`area_collapse'") ///
				label dec(4) keep (log_sum_pix) ///
				bdec(3) addstat(Adjusted Within R-squared, e(r2_a_within), ///
				Within R-squared, e(r2_within))
				
			*** electricity
				foreach elec_lp of varlist ln_pwr_consum ln_elec_access {
						xtreg log_`var' `elec_lp' i.year_f, fe robust ///
						cluster(iso3c_f)
						
						outreg2 using "$outreg_file_natl_yr", append ///
						ctitle("`var'_FE_electr_`time_collapse'_`area_collapse'") ///
						label dec(4) keep (`elec_lp') ///
						bdec(3) addstat(Between R-squared, e(r2_b), ///
						Within R-squared, e(r2_w), ///
						Overall R-squared, e(r2_o))
						
						reghdfe log_`var' `elec_lp', absorb(iso3c_f year_f) ///
						vce(cluster iso3c_f)
						
						outreg2 using "$outreg_file_natl_yr", append ///
						ctitle("`var'_REGHDFE_electr_`time_collapse'_`area_collapse'") ///
						label dec(4) keep (`elec_lp') ///
						bdec(3) addstat(Adjusted Within R-squared, e(r2_a_within), ///
						Within R-squared, e(r2_within))
				}

		}		
	}
}

//
// // ======================================
// 	import delimited "$hf_input/merged_month_gid_2.csv", clear
// 	keep iso3c year sum_pix oxford log_oxford
// 	foreach var in iso3c year sum_pix oxford {
// 	    drop if missing(`var')
// 	}
// 	rename (sum_pix oxford log_oxford) (m_sum_pix m_oxford m_log_oxford)
// 	tempfile tempmerge
// 	save `tempmerge'
//	
// 	use "$hf_input/NTL_GDP_month_ADM2.dta", clear
// 	replace sum_pix = 0 if sum_pix <=0
// 	replace pol_area = 0 if sum_pix <=0
// 	collapse (sum) sum_pix pol_area (mean) ox_rgdp_lcu, by(iso3c year quarter)
// 	collapse (sum) sum_pix pol_area ox_rgdp_lcu, by(iso3c year)
// 	replace ox_rgdp_lcu = . if ox_rgdp_lcu == 0
// 	replace sum_pix = sum_pix/pol_area
// 	drop pol_area
// 	foreach var in iso3c year sum_pix ox_rgdp_lcu {
// 	    drop if missing(`var')
// 	}
// 	rename * bruce_*
// 	rename (bruce_iso3c bruce_year) (iso3c year)
// 	mmerge iso3c year using `tempmerge'
// 	drop _m
// 	rename (bruce_ox_rgdp_lcu) (bruce_oxford)
// 	gen diff = (bruce_oxford - m_oxford)
// 	br if abs(diff)>20
// 	gen ratio = diff / m_oxford
//	
//	
















// *** ----------------------------------------------------------------------
// *** Check if NTL aggregation downloaded online for PRIOR data is accurate
// *** ----------------------------------------------------------------------
// 	clear all
// 	set more off 
//	
// 	global outreg_file_pre_2013 "$hf_input/natl_reg_hender_pre_2013_13.xls"
//	
// *** get the dataset of pixel AREA from our original NTL dataset
// 	import delimited "$hf_input/none_none.csv", clear
// 	bysort iso3c: egen median_sum_area = median(sum_area)
// 	collapse (firstnm) median_sum_area, by(iso3c)
// 	rename median_sum_area sum_area
// 	tempfile pixel_area
// 	save `pixel_area'
//
// *** Import dataset
// 	import delimited "$hf_input/Nighttime_Lights_ADM2_1992_2013.csv", clear
// 	collapse (sum) sum_light, by(countrycode countryname year)
// // 	rename (mean_light) (sum_light)
//	
// *** Merge with pixel area:
// 	rename countrycode iso3c
// 	mmerge iso3c using `pixel_area'
// 	keep if _m == 3
// 	drop _m
//	
// *** Merge w/ GDP measures:
// 	mmerge iso3c year using "$hf_input/natl_accounts_GDP_annual_all.dta"
// 	keep if _m == 3
// 	keep iso3c countryname year sum_light Oxford WDI sum_area
// 	rename sum_light sum_pix
// 	replace sum_pix = sum_pix / sum_area
// 	label variable sum_pix "Sum pixels / Area"
//	
//     export delimited "$hf_input/henderson.csv", replace
//	
// *** Get logged 1-yr log variables:
// 		foreach var of varlist sum_pix Oxford WDI {
// 			sort iso3c year
// 			loc lab: variable label `var'
// 			gen log_`var' = ln(`var')
// 			label variable log_`var' "Log `lab'" 
// 		}
// 	br
//
// *** get rid of post-2008
// // 	keep if year <= 2008
//	
// ***	Make country and year fixed effects.
// 	encode iso3c, gen(iso3c_f)
// 	tostring year, replace
// 	encode year, gen(year_f)
//
// *** Regressions on log(GDP)~log(NTL)
// 	foreach var of varlist Oxford WDI{
// 		regress log_`var' log_sum_pix i.year_f i.iso3c_f, robust
// 		outreg2 using "$outreg_file_pre_2013", append ///
// 		ctitle("`var'_OLS_`time_collapse'_`area_collapse'") ///
// 		label dec(4) keep (log_sum_pix)
// 	}
//	
// *** Perform the same regressions but using FE estimator. 
// *** Should have same coefficients.
// 	destring year, replace
// 	xtset iso3c_f year
// 	foreach var of varlist Oxford WDI{
// 		xtreg log_`var' log_sum_pix i.year_f, fe robust
// 		outreg2 using "$outreg_file_pre_2013", append ///
// 		ctitle("`var'_FE_`time_collapse'_`area_collapse'") ///
// 		label dec(4) keep (log_sum_pix)
// 	}
//	
// *** ----------------------------------------------------------------------
// *** Compare HWS with Australian downloaded data from the internet:
// *** ----------------------------------------------------------------------
//
// *** Import the Australian dataset:
// 	import delimited "$hf_input/henderson.csv", clear
// 	gen log_lights_austra = ln(sum_pix)
// 	keep iso3c year log_lights_austra
// 	tempfile australian
// 	save `australian'
//	
// *** Import the henderson dataset:
// 	use "$hf_input/HWS AER replication/hsw_final_tables_replication/global_total_dn_uncal.dta", replace
//	
// *** make sure that there's a 1-1 relationship between isonv10 iso3v10 country 
// *** codes
// 	preserve 
// 	keep isonv10 iso3v10
// 	duplicates drop
// 	tab isonv10
// 	return list, all
// 	loc before `r(N)'
// 	keep iso3v10
// 	duplicates drop
// 	tab iso3v10
// 	assert `r(N)' == `before'
// 	restore
//
// *** keep the variables we're interested in.
// 	keep iso3v10 year lndn
// 	rename (iso3v10 lndn) (iso3c log_lights_HWS)
//	
//
// *** merge the two datasets
// 	mmerge iso3c year using `australian'
// 	drop _m
//
// *** make sure that the number of observations per country-year is 1.
// 	preserve
// 	duplicates tag iso3c year, gen (dup_id_cov)
// 	assert dup_id_cov==0
// 	restore
//	
// *** take a linear regression between the two
// 	regress log_lights_austra log_lights_HWS
// 	outreg2 using "$hf_input/lm_aus_hws.txt", replace
//	
// *** plot a scatterplot between the two	
// 	label variable log_lights_austra "ln(lighs/area) from Australian ADM2 datasource."
// 	scatter(log_lights_austra log_lights_HWS)
// 	graph export "$hf_input/scatterplot_AUS_HWS.pdf", replace
//
//	
// *** ----------------------------------------------------------------------
// *** Compare 2012-2013 for Henderson vs. VIIRS vs. Australian DMSP on Henderson 
// *** GDP and Oxford GDP:
// *** ----------------------------------------------------------------------
//
// // // import henderson dataset from the AER replication file
// // 	use "$hf_input\HWS AER replication\hsw_final_tables_replication\global_total_dn_uncal.dta", clear
// //
// // // keep only the log (GDP) and log(lights / area) variables for year 2012-2013
// // 	keep lngdpwdilocal lndn year iso3v10
// // 	keep if year == 2012 | year == 2013
// // 	decode(isonv10), generate(iso3c)
// //	
// // // save as temporary file
// // 	tempfile HWS_AER
// // 	save `HWS_AER'
//
// // import australian DMSP dataset
// 	import delimited "$hf_input/henderson.csv", clear
// 	gen log_lights_austra = ln(sum_pix)
//	
// // keep only the log(lights / area) variables
// 	keep iso3c year log_lights_austra
//		
// // save as temporary file
// 	tempfile australian
// 	save `australian'
//	
// // import our VIIRS dataset
// 	import delimited "$hf_input/merged_month_gid_2.csv", clear
//
// // keep only the log (GDP) and log(lights / area) variables
// 	drop _merge iso3c_f year_f
//		
// // save as temporary file
// 	tempfile viirs
// 	save `viirs'
//	
// // merge the 3 datasets together
// 	mmerge iso3c year using `australian'
//	
// // drop those that were not merged well
// 	drop if _m != 3
// 	drop _m
//
// // regress log(GDP) ~ log(lights / area) using the Oxford GDP measures and the 
// // Henderson WDI GDP measures, and export to a table.
// 	keep iso3c year log_sum_pix log_wdi log_lights_austra
// 	foreach var in iso3c year log_sum_pix log_wdi log_lights_austra {
// 	    drop if missing(`var')
// 	}
// 	label variable log_sum_pix "Log(Pixels/Area VIIRS)"
// 	label variable log_wdi "Log(WDI GDP, LCU)"
// 	label variable log_lights_austra "Log(Pixels/Area DMSP)"
// 	encode iso3c, generate(iso3c_f)
//	
// 	rename(log_lights_austra log_sum_pix) (DMSP VIIRS)
//	
// 	foreach var in DMSP VIIRS {
// 	    reghdfe log_wdi `var', absorb(iso3c year) vce(cluster iso3c)
// 		outreg2 using "$outreg_file_compare_12_13", bdec(3) ///
// 		addstat(Adjusted Within R-squared, e(r2_a_within), ///
// 		Within R-squared, e(r2_within)) append ///
// 		ctitle("`var' reghdfe") label dec(4) keep (`var')
//		
// 		xtset iso3c_f year
// 		xi: xtreg log_wdi `var' i.year, fe robust cluster(iso3c_f)
// 		outreg2 using "$outreg_file_compare_12_13", bdec(3) ///
// 		addstat(Between R-squared, e(r2_b), ///
// 				Within R-squared, e(r2_w), ///
// 				Overall R-squared, e(r2_o)) append ///
// 		ctitle("`var' xtreg") label dec(4) keep (`var')
// 	}
//
//	
// *** ----------------------------------------------------------------------
// *** Take a quantile regression across GDP measures:
// *** ----------------------------------------------------------------------
// import delimited "$hf_input/merged_month_gid_2.csv", clear
// drop _merge iso3c_f year_f
// encode iso3c, generate(iso3c_f)
// tostring year, replace
// encode year, generate(year_f)
// label variable log_sum_pix "Log(Pixels/Area VIIRS)"
// label variable log_wdi "Log(WDI GDP, LCU)"
//
// foreach var in iso3c year log_sum_pix log_wdi iso3c_f {
// 	drop if missing(`var')
// }
// cls
// qreg log_wdi log_sum_pix i.iso3c_f i.year_f, ///
// quantile(50) iterate(600) nolog vce(robust, )
//
// // quantile regression yields stronger relationship between lights and 
// // GDP when countries are in middle of growth.
//
// *** ----------------------------------------------------------------------
// *** Import Electricity Data and run Storeygard regression
// *** ----------------------------------------------------------------------
// import delimited "$hf_input/merged_none_none.csv", clear
// mmerge iso3c year using "$hf_input/electricity.dta"
// keep if _m == 3
// drop _merge
//
// *** make sure we only have 1 country-year pairs:
// 	preserve
// 	sort iso3c year
// 	keep iso3c year
// 	duplicates tag iso3c year, gen (dup_id_cov)
// 	assert dup_id_cov==0
// 	restore
//
// *** Get categorical variables:
// 	drop *_f
// 	encode iso3c, generate(iso3c_f)
// 	tostring year, replace
// 	encode year, generate(year_f)
//
// label variable log_wdi "Log(WDI GDP, LCU)"
//
// *** get log variables:
//	
//
// *** drop missing variables:
// 	foreach var in iso3c year ln_pwr_consum ln_elec_access log_wdi iso3c_f {
// 		drop if missing(`var')
// 	}
// 	cls
//
// *** regress electricity consumption on GDP:
//
// 	foreach elec_lp of varlist ln_pwr_consum ln_elec_access {
// 	foreach var of varlist Oxford IMF_quart PWT IMF_WEO WDI {
// 			xtreg log_`var' `elec_lp' i.year_f, fe robust cluster(iso3c_f)
//			
// 			outreg2 using "$outreg_file_natl_yr", append ///
// 			ctitle("`var'_FE_`time_collapse'_`area_collapse'") ///
// 			label dec(4) keep (`elec_lp') ///
// 			bdec(3) addstat(Between R-squared, e(r2_b), ///
// 			Within R-squared, e(r2_w), ///
// 			Overall R-squared, e(r2_o))
//			
// 			reghdfe log_`var' `elec_lp', absorb(iso3c_f year_f) ///
// 			vce(cluster iso3c_f)
//			
// 			outreg2 using "$outreg_file_natl_yr", append ///
// 			ctitle("`var'_REGHDFE_`time_collapse'_`area_collapse'") ///
// 			label dec(4) keep (`elec_lp') ///
// 			bdec(3) addstat(Adjusted Within R-squared, e(r2_a_within), ///
// 			Within R-squared, e(r2_within))
// 	}
// 	}













// foreach time_collapse in month none {
// foreach area_collapse in gid_2 none {
// 	use "$hf_input/base_NTL.dta", clear
// 	rename pol_area sum_area
// 	if ("`time_collapse'" != "none") & ("`area_collapse'" != "none") {
// 		drop if sum_pix < 0
// 		collapse (sum) sum_area sum_pix (mean) pwt_rgdpna imf_rgdp_lcu WDI ///
// 		imf_quart_nom_gdp imf_quart_rgdp ox_rgdp_lcu, by(year quarter `time_collapse' `area_collapse' iso3c)
// 	}
// 	collapse (sum) sum_pix sum_area, by(year quarter)
// 	collapse (sum) sum_pix sum_area, by(year iso3c)
// 	export delimited "$hf_input/`time_collapse'_`area_collapse'.csv", replace
// }
// }
//
// *** Create a dataset where negatives are filled downwards:
// 	use "$hf_input/base_NTL.dta", clear
// 	replace sum_pix = . if sum_pix < 0
// 	sort iso3c gid_2 year month
// 	sort gid_2 year month
// 	forval i = 0/13 {
// 		sort gid_2 year month
// 		by gid_2 : replace sum_pix = sum_pix[_n-1] if missing(sum_pix)
// 	}
// 	assert sum_pix != . if year != 2012
// 	drop if sum_pix == .
// 	rename pol_area sum_area
// 	collapse (sum) sum_pix sum_area, by(year iso3c)
// 	export delimited "$hf_input/negatives_filled_downwards.csv", replace