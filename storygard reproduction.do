cls
// re-producing the storygard regressions under different methods of cleaning
// the underlying negative night lights data

// Produce datasets:
// e.g.
// 1. collapse by ADM2 quarter and drop if negative --> collapse to country-year
// 2. collapse by country month and drop if negative --> collapse to country-year
// 3. collapse by ADM2 quarter and drop if negative --> collapse to country-year
// 4. collapse by country quarter and drop if negative --> collapse to country-year
// 5. collapse by ADM2 month and drop if negative --> collapse to country-year
// 6. collapse by country year and drop if negative --> collapse to country-year

// Macros -----------------------------------------------------------------
	foreach user in "`c(username)'" {
		global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
		global hf_input "$root/HF_measures/input/"
		global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
	}

	global outreg_file_natl_yr "$hf_input/natl_reg_hender_35.xls"
	global outreg_file_natl_quart "$hf_input/quart_reg_hender_1.xls"
	global outreg_file_compare_12_13 "$hf_input/natl_reg_dmsp_8.xls"
	global GDP_compare_HWS_WDI "$hf_input/GDP_compare_HWS_WDI_8.xls" 

	clear all
	set more off 
	
// ------------------------------------------------------------------------
// Produce NTL datasets that have negatives deleted at certain points:
// ------------------------------------------------------------------------

// Note: Night lights are missing 2012 Q1 data. So, since Oxford was aggregated 
// and collapsed AFTER merging--Oxford doesn't have Q1 stuff. 
	use "$hf_input/NTL_GDP_month_ADM2.dta", clear
	keep iso3c gid_2 mean_pix sum_pix year quarter month pol_area pwt_rgdpna ///
	imf_rgdp_lcu WDI ox_rgdp_lcu

// Drop negative values at the month-ADM2 level
// 	!!!!!!!!!!!!!!!!!!!!!!!!!!!replace sum_pix = 0 if sum_pix < 0
	drop if sum_pix < 0
	
// Rename pol_area to sum_area
	rename pol_area sum_area
	
// Collapse to a year-quarter level, taking a mean of GDP values
	collapse (sum) sum_area sum_pix (mean) pwt_rgdpna imf_rgdp_lcu WDI ///
	ox_rgdp_lcu, by(year quarter iso3c)

// Rename the GDP variables
	rename (ox_rgdp_lcu pwt_rgdpna imf_rgdp_lcu WDI) ///
	(Oxford PWT IMF_WEO WDI)
	
// Save the dataset (quarterly level)
	sort iso3c year
	save "$hf_input/natl_accounts_GDP_quarterly_all.dta", replace
	
// Collapse to a year level, taking a sum of GDP values
	collapse (sum) sum_area sum_pix Oxford ///
	(mean) PWT IMF_WEO WDI, by(year iso3c)
	
// Since collapsing by sum inserts 0s if all the summed values were missing, 
// replace summed quarterly (now annual) GDP values with missing if they're 0
	replace Oxford = . if Oxford  == 0

// Make sure that we still have unique IDs across ISO3C and year:
	duplicates tag iso3c year, gen(dup)
	assert dup == 0
	drop dup
	
// Merge with electricity data:
	mmerge year iso3c using "$hf_input/electricity.dta"
	
// Make sure that we still have unique IDs across ISO3C and year:
	drop _m
	duplicates tag iso3c year, gen(dup)
	assert dup == 0
	drop dup
	sort iso3c year

// Check: US GDP in 2020 for each GDP measure should be anywhere from 18,000 to 
// 23,000 (based on year)
// Importantly, IMF quarterly GDP was not included in this exercise, since we're 
// missing so many observations
	preserve
	foreach var of varlist Oxford PWT IMF_WEO WDI{
	keep if iso3c=="USA" & year == 2019
	assert `var' >= 18000 & `var' <= 23000
	}
	restore
	
	sort iso3c year
	save "$hf_input/natl_accounts_GDP_annual_all.dta", replace


// -----------------------------------------------
// Run regressions:
// -----------------------------------------------
	
use "$hf_input/natl_accounts_GDP_annual_all.dta", clear
sort iso3c year
fillin iso3c year
drop _fillin
sort iso3c year
	
// replace sum pixels with sum pixels divided by area.
	replace sum_pix = sum_pix / sum_area
	label variable sum_pix "Sum pixels / Area"
	
// get logged variables:
	foreach var of varlist sum_pix Oxford PWT IMF_WEO WDI {
		sort iso3c year
		loc lab: variable label `var'
		gen log_`var' = ln(`var')
		label variable log_`var' "Log `lab'" 
	}
	
//	make country and year fixed effects.
	encode iso3c, gen(iso3c_f)
	tostring year, replace
	encode year, gen(year_f)
	
// Perform the same regressions but using FE estimator. 
// Should have same coefficients.
	destring year, replace
	xtset iso3c_f year
	foreach var of varlist Oxford PWT IMF_WEO WDI{
		
		// night-lights XTREG
			xtreg log_`var' log_sum_pix i.year_f, fe robust ///
			cluster(iso3c_f)
			
			outreg2 using "$outreg_file_natl_yr", append ///
			ctitle("`var'_FE") ///
			label dec(4) keep (log_sum_pix) ///
			bdec(3) addstat(Between R-squared, e(r2_b), ///
			Within R-squared, e(r2_w), ///
			Overall R-squared, e(r2_o))
			
		// night-lights REGHDFE
			reghdfe log_`var' log_sum_pix, absorb(iso3c_f year_f) ///
			vce(cluster iso3c_f)
			
			outreg2 using "$outreg_file_natl_yr", append ///
			ctitle("`var'_REGHDFE") ///
			label dec(4) keep (log_sum_pix) ///
			bdec(3) addstat(Adjusted Within R-squared, e(r2_a_within), ///
			Within R-squared, e(r2_within))
			
		// electricity
			foreach elec_lp of varlist ln_pwr_consum ln_elec_access {
					xtreg log_`var' `elec_lp' i.year_f, fe robust ///
					cluster(iso3c_f)
					
					outreg2 using "$outreg_file_natl_yr", append ///
					ctitle("`var'_FE_electr") ///
					label dec(4) keep (`elec_lp') ///
					bdec(3) addstat(Between R-squared, e(r2_b), ///
					Within R-squared, e(r2_w), ///
					Overall R-squared, e(r2_o))
					
					reghdfe log_`var' `elec_lp', absorb(iso3c_f year_f) ///
					vce(cluster iso3c_f)
					
					outreg2 using "$outreg_file_natl_yr", append ///
					ctitle("`var'_REGHDFE_electr") ///
					label dec(4) keep (`elec_lp') ///
					bdec(3) addstat(Adjusted Within R-squared, e(r2_a_within), ///
					Within R-squared, e(r2_within))
			}
	}
// ----------------------------------------------------------------------
// Run quarterly regressions
// ----------------------------------------------------------------------
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
use "$hf_input/natl_accounts_GDP_quarterly_all.dta", clear
sort iso3c year
fillin iso3c year quarter
drop _fillin
sort iso3c year quarter
drop PWT IMF_WEO WDI

// replace sum pixels with sum pixels divided by area.
	replace sum_pix = sum_pix / sum_area
	label variable sum_pix "Sum pixels / Area"
	
// get logged variables:
	foreach var of varlist sum_pix Oxford {
		sort iso3c year
		loc lab: variable label `var'
		gen log_`var' = ln(`var')
		label variable log_`var' "Log `lab'" 
	}
	
//	make country and year fixed effects.
	encode iso3c, gen(iso3c_f)
	tostring year, replace
	encode year, gen(year_f)
	tostring quarter, replace
	encode quarter, gen(quarter_f)
	
// Perform the same regressions but using FE estimator. 
// Should have same coefficients.
	destring year, replace

	foreach var of varlist Oxford {
		
		// night-lights REGHDFE
			reghdfe log_`var' log_sum_pix, absorb(iso3c_f year_f quarter_f) ///
			vce(cluster iso3c_f)
			
			outreg2 using "$outreg_file_natl_quart", append ///
			ctitle("`var'_REGHDFE") ///
			label dec(4) keep (log_sum_pix) ///
			bdec(3) addstat(Adjusted Within R-squared, e(r2_a_within), ///
			Within R-squared, e(r2_within))
	}

// ----------------------------------------------------------------------
// Compare 2012-2013 for Henderson vs. VIIRS vs. Australian DMSP on Henderson 
// GDP and Oxford GDP:
// ----------------------------------------------------------------------

// First, since the DMSP dataset doesn't have polygon area, get it from the 
// original NTL dataset
// Note: 
// The objectIDs partition every country. If I sum the pixel area across country,
// there are no overlapping objectIDs. HOWEVER, it might be the case that there 
// are multiple GID_2's assigned to different objectIDs since the internationally 
// aggreed upon ADM2 bounds aren't perfect. 
	use "$hf_input/NTL_GDP_month_ADM2.dta", clear
	keep if year == 2013
	keep iso3c pol_area
	collapse (sum) pol_area, by(iso3c)
	tempfile pol_areas
	save `pol_areas'

// Import DMSP dataset
	import delimited "$hf_input/Nighttime_Lights_ADM2_1992_2013.csv", clear
	collapse (sum) sum_light, by(countrycode year)
	rename (countrycode sum_light) (iso3c sum_light_dmsp)
	
// keep only the log(lights / area) variables
	keep iso3c year sum_light_dmsp

// save as temporary file
	tempfile dmsp_data
	save `dmsp_data'
	
// import our VIIRS dataset
	use "$hf_input/natl_accounts_GDP_annual_all.dta", clear
	keep iso3c year sum_area sum_pix Oxford PWT IMF_WEO WDI
	rename sum_pix sum_light_viirs
	
// merge the 2 datasets together
	mmerge iso3c year using `dmsp_data'
	keep if _m == 3
	drop _m
	mmerge iso3c using `pol_areas'
	keep if _m == 3
	drop _m

// keep the overlapping year:
	keep if year == 2013 | year == 2012
	foreach var in iso3c year sum_area pol_area sum_light_viirs ///
	sum_light_dmsp Oxford PWT IMF_WEO WDI {
	    drop if missing(`var')
	}
	
// replace sum pixels with sum pixels divided by area. the difference here 
// between sum_area and pol_area is that sum_area has the polygons DELETED if 
// the ADM2 region had a negative night lights at the month level for VIIRS. 
// pol_area is actually the entire area of the country. Thus, in order to get 
// the light "density", we have to use sum_area for VIIRS and pol_area for DMSP, 
// as DMSP has no negative issue.
	replace sum_light_viirs = sum_light_viirs / sum_area
	replace sum_light_dmsp = sum_light_dmsp / pol_area
	
// get logged variables:
	foreach var of varlist sum_light_dmsp sum_light_viirs Oxford PWT IMF_WEO WDI {
		sort iso3c year
		loc lab: variable label `var'
		gen log_`var' = ln(`var')
		label variable log_`var' "Log `lab'" 
	}

	rename(log_sum_light_dmsp log_sum_light_viirs) (DMSP VIIRS)
	label variable DMSP "Log(Pixels/Area DMSP)"
	label variable VIIRS "Log(Pixels/Area VIIRS)"
	
//	make country and year fixed effects.
	encode iso3c, gen(iso3c_f)
	tostring year, replace
	encode year, gen(year_f)
	
// Perform the same regressions but using FE estimator. 
// Should have same coefficients.
	destring year, replace
	xtset iso3c_f year
	
	save "two_years_countries.dta", replace
	
// do regressions
	
	foreach gdp_var in Oxford PWT IMF_WEO WDI{
	foreach light_var in DMSP VIIRS {
// 		regress log_`gdp_var' `light_var' i.year_f
// 		outreg2 using "$outreg_file_compare_12_13", bdec(3) ///
// 		ctitle("`gdp_var'") label dec(4) keep (`light_var')
		

		reghdfe log_`gdp_var' `light_var', absorb(iso3c) vce(cluster iso3c)
		outreg2 using "$outreg_file_compare_12_13", bdec(3) ///
		addstat(Adjusted Within R-squared, e(r2_a_within), ///
		Within R-squared, e(r2_within)) append ///
		ctitle("`gdp_var' reghdfe") label dec(4) keep (`var')
		
		xi: xtreg log_`gdp_var' `light_var', fe robust cluster(iso3c_f)
		outreg2 using "$outreg_file_compare_12_13", bdec(3) ///
		addstat(Between R-squared, e(r2_b), ///
		Within R-squared, e(r2_w), ///
		Overall R-squared, e(r2_o)) append ///
		ctitle("`gdp_var' xtreg") label dec(4) keep (`var')		
	
	}
	}	

// ----------------------------------------------------------------------
// Compare our vintage of WDI data to Henderson WDI GDP data:
// ----------------------------------------------------------------------

// use henderson's AER replication file
use "$hf_input/HWS AER replication/hsw_final_tables_replication/global_total_dn_uncal.dta", clear
keep year iso3v10 country lngdpwdilocal
rename iso3v10 iso3c
sort iso3c year
tempfile gdp_hws
save `gdp_hws'

// merge with our dataset of WDI data
use "$hf_input/imf_pwt_GDP_annual.dta", clear
sort iso3c year
mmerge iso3c year using `gdp_hws'

// Henderson's GDP measures are not in billions
replace WDI = (10^9)*WDI

// get comparable log GDP and not-log GDP
gen ln_wdi = ln(WDI)
gen exp_hws_wdi = exp(lngdpwdilocal)

// get fixed effect for country coded, and drop missing observations
encode iso3c, gen(iso3c_f)
keep iso3c iso3c_f year WDI exp_hws_wdi lngdpwdilocal ln_wdi
foreach var in WDI lngdpwdilocal ln_wdi exp_hws_wdi {
	drop if missing(`var')
}

// check how many countries we have
gen count = 1
bysort year: egen count1 = total(count)

// aesthetics: labels
label variable ln_wdi "Log(GDP) (constant LCU, 2021 version)"
label variable lngdpwdilocal "Log(GDP) (constant LCU, HWS version)"
label variable WDI "GDP (constant LCU, 2021 version)"
label variable exp_hws_wdi "GDP (constant LCU, HWS version)"

// regressions
reghdfe lngdpwdilocal ln_wdi, absorb(iso3c) vce(cluster iso3c)
outreg2 using "$GDP_compare_HWS_WDI", bdec(3) ///
addstat(Adjusted Within R-squared, e(r2_a_within), ///
Within R-squared, e(r2_within)) append ///
ctitle("Log(GDP) (constant LCU, Henderson)") label dec(4) keep (ln_wdi) ///
addtext(Country FE, Yes)

regress lngdpwdilocal ln_wdi, robust
outreg2 using "$GDP_compare_HWS_WDI", bdec(3) ///
ctitle("Log(GDP) (constant LCU, Henderson)") label dec(4) ///
addtext(Country FE, No)

reghdfe exp_hws_wdi WDI, absorb(iso3c) vce(cluster iso3c)
outreg2 using "$GDP_compare_HWS_WDI", bdec(3) ///
addstat(Adjusted Within R-squared, e(r2_a_within), ///
Within R-squared, e(r2_within)) append ///
ctitle("GDP (constant LCU Henderson)") label dec(4) keep (WDI) ///
addtext(Country FE, Yes)

regress exp_hws_wdi WDI, robust
outreg2 using "$GDP_compare_HWS_WDI", bdec(3) ///
ctitle("GDP (constant LCU Henderson)") label dec(4) ///
addtext(Country FE, No)
bysort iso3c: gen cumsum = sum(count)
gen iso3c_label = iso3c if (cumsum == 1)

// regression diagnostics and graphs:
if (1==0) {
	set scheme s1mono
	scatter exp_hws_wdi WDI, mlabel(iso3c_label)
	scatter lngdpwdilocal ln_wdi, mlabel(iso3c_label)

	predict r, rstudent
	sort r
	lvr2plot, mlabel(state)
	avplot single, mlabel(state)
	avplots
	predict r, resid
	kdensity r, normal
	pnorm r
	qnorm r
	rvfplot, yline(0)
}

// import
import excel "hf_input/simulated deflator.xlsx", sheet("Sheet1") firstrow clear

// convert to numeric
destring Year CurrentGDP1 inflation cumulativeinflation ratiodeflatoryr1 ///
ratiodeflatoryr15 Constantyr1GDP2 Constantyr15GDP3, replace ignore(`","') ///
force float
encode Country, gen(Country_f)

replace Constantyr15GDP3 = Constantyr15GDP3 / 100 if Country == "b"
replace Constantyr1GDP2 = Constantyr1GDP2 / 100 if Country == "b"
scatter Constantyr1GDP2 Constantyr15GDP3, mlabel(Country)

gen ln_base = ln(Constantyr15GDP3)
gen ln_adj = ln(Constantyr1GDP2)
scatter ln_adj ln_base, mlabel(Country)

// ----------------------------------------------------------------------
// Henderson Long Differences Replication with our data
// ----------------------------------------------------------------------

// import our GDP and lights metrics
use "$hf_input/natl_accounts_GDP_annual_all.dta", clear

// replace sum pixels with sum pixels divided by area.
// replace sum_pix = sum_pix / sum_area
// label variable sum_pix "Sum pixels / Area"

keep iso3c year sum_pix Oxford PWT WDI
keep if inlist(year, 2013, 2014, 2019, 2020)

// create variables log(mean(2013-2014 GDP)) and log(mean(2013-2014 lights))
// create variables log(mean(2019-2020 GDP)) and log(mean(2019-2020 lights))
foreach i in sum_pix Oxford PWT WDI {
	gen ln`i' = ln(`i')
	sort iso3c year
	gen lnmean`i' = (ln`i' + ln`i'[_n-1])/2 if iso3c == iso3c[_n-1]
// take the difference between the log mean variables
}

// take the difference between the log mean variables
keep if inlist(year, 2020, 2014)
foreach i in sum_pix Oxford PWT WDI {
	sort iso3c year
	gen longdifflnmean`i' = (lnmean`i' - lnmean`i'[_n-1]) if iso3c == iso3c[_n-1]
}

export delimited "$hf_input/long_diff_replication.csv", replace
tempfile longdiff
save `longdiff'
// plot the differences

set scheme s1mono
foreach i in Oxford PWT WDI {
use `longdiff', clear
keep if year == 2020
drop if inlist(iso3c, "VUT", "VEN", "SLB")
// local i WDI
drop if missing(longdifflnmean`i') | missing(longdifflnmeansum_pix)

twoway (scatter longdifflnmean`i' longdifflnmeansum_pix, ///
yscale(range(-.4 .6)) ///
xscale(range(-.2 1.4)) ///
ylabel(-.4(.2).6) xlabel(-.2(.2)1.4) msize(tiny) mlabel(iso3) mlabsize(tiny) ///
ytitle("ln(GDP 20-19) - ln(GDP 13-14)") ///
xtitle("ln(lights 20-19) - ln(lights 13-14)") ///
caption("VUT, VEN, and SLB dropped") ///
title("Figure 6b. `i' GDP versus lights: long differences")) ///
(lowess longdifflnmean`i' longdifflnmeansum_pix), note("bandwidth = .8") legend(off)
graph export "$hf_input/Fig6b_LDscatter`i'.png", replace
}

// (line longdifflnmeansum_pix longdifflnmeansum_pix, lcolor(maroon)) ///







































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
















// // ----------------------------------------------------------------------
// // Check if NTL aggregation downloaded online for PRIOR data is accurate
// // ----------------------------------------------------------------------
// 	clear all
// 	set more off 
//	
// 	global outreg_file_pre_2013 "$hf_input/natl_reg_hender_pre_2013_13.xls"
//	
// // get the dataset of pixel AREA from our original NTL dataset
// 	import delimited "$hf_input/none_none.csv", clear
// 	bysort iso3c: egen median_sum_area = median(sum_area)
// 	collapse (firstnm) median_sum_area, by(iso3c)
// 	rename median_sum_area sum_area
// 	tempfile pixel_area
// 	save `pixel_area'
//
// // Import dataset
// 	import delimited "$hf_input/Nighttime_Lights_ADM2_1992_2013.csv", clear
// 	collapse (sum) sum_light, by(countrycode countryname year)
// // 	rename (mean_light) (sum_light)
//	
// // Merge with pixel area:
// 	rename countrycode iso3c
// 	mmerge iso3c using `pixel_area'
// 	keep if _m == 3
// 	drop _m
//	
// // Merge w/ GDP measures:
// 	mmerge iso3c year using "$hf_input/natl_accounts_GDP_annual_all.dta"
// 	keep if _m == 3
// 	keep iso3c countryname year sum_light Oxford WDI sum_area
// 	rename sum_light sum_pix
// 	replace sum_pix = sum_pix / sum_area
// 	label variable sum_pix "Sum pixels / Area"
//	
//     export delimited "$hf_input/henderson.csv", replace
//	
// // Get logged 1-yr log variables:
// 		foreach var of varlist sum_pix Oxford WDI {
// 			sort iso3c year
// 			loc lab: variable label `var'
// 			gen log_`var' = ln(`var')
// 			label variable log_`var' "Log `lab'" 
// 		}
// 	br
//
// // get rid of post-2008
// // 	keep if year <= 2008
//	
// //	Make country and year fixed effects.
// 	encode iso3c, gen(iso3c_f)
// 	tostring year, replace
// 	encode year, gen(year_f)
//
// // Regressions on log(GDP)~log(NTL)
// 	foreach var of varlist Oxford WDI{
// 		regress log_`var' log_sum_pix i.year_f i.iso3c_f, robust
// 		outreg2 using "$outreg_file_pre_2013", append ///
// 		ctitle("`var'_OLS_`time_collapse'_`area_collapse'") ///
// 		label dec(4) keep (log_sum_pix)
// 	}
//	
// // Perform the same regressions but using FE estimator. 
// // Should have same coefficients.
// 	destring year, replace
// 	xtset iso3c_f year
// 	foreach var of varlist Oxford WDI{
// 		xtreg log_`var' log_sum_pix i.year_f, fe robust
// 		outreg2 using "$outreg_file_pre_2013", append ///
// 		ctitle("`var'_FE_`time_collapse'_`area_collapse'") ///
// 		label dec(4) keep (log_sum_pix)
// 	}
//	
// // ----------------------------------------------------------------------
// // Compare HWS with Australian downloaded data from the internet:
// // ----------------------------------------------------------------------
//
// // Import the Australian dataset:
// 	import delimited "$hf_input/henderson.csv", clear
// 	gen log_lights_austra = ln(sum_pix)
// 	keep iso3c year log_lights_austra
// 	tempfile australian
// 	save `australian'
//	
// // Import the henderson dataset:
// 	use "$hf_input/HWS AER replication/hsw_final_tables_replication/global_total_dn_uncal.dta", replace
//	
// // make sure that there's a 1-1 relationship between isonv10 iso3v10 country 
// // codes
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
// // keep the variables we're interested in.
// 	keep iso3v10 year lndn
// 	rename (iso3v10 lndn) (iso3c log_lights_HWS)
//	
//
// // merge the two datasets
// 	mmerge iso3c year using `australian'
// 	drop _m
//
// // make sure that the number of observations per country-year is 1.
// 	preserve
// 	duplicates tag iso3c year, gen (dup_id_cov)
// 	assert dup_id_cov==0
// 	restore
//	
// // take a linear regression between the two
// 	regress log_lights_austra log_lights_HWS
// 	outreg2 using "$hf_input/lm_aus_hws.txt", replace
//	
// // plot a scatterplot between the two	
// 	label variable log_lights_austra "ln(lighs/area) from Australian ADM2 datasource."
// 	scatter(log_lights_austra log_lights_HWS)
// 	graph export "$hf_input/scatterplot_AUS_HWS.pdf", replace
//
//	

//
//	
// // ----------------------------------------------------------------------
// // Take a quantile regression across GDP measures:
// // ----------------------------------------------------------------------
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
// // ----------------------------------------------------------------------
// // Import Electricity Data and run Storeygard regression
// // ----------------------------------------------------------------------
// import delimited "$hf_input/merged_none_none.csv", clear
// mmerge iso3c year using "$hf_input/electricity.dta"
// keep if _m == 3
// drop _merge
//
// // make sure we only have 1 country-year pairs:
// 	preserve
// 	sort iso3c year
// 	keep iso3c year
// 	duplicates tag iso3c year, gen (dup_id_cov)
// 	assert dup_id_cov==0
// 	restore
//
// // Get categorical variables:
// 	drop *_f
// 	encode iso3c, generate(iso3c_f)
// 	tostring year, replace
// 	encode year, generate(year_f)
//
// label variable log_wdi "Log(WDI GDP, LCU)"
//
// // get log variables:
//	
//
// // drop missing variables:
// 	foreach var in iso3c year ln_pwr_consum ln_elec_access log_wdi iso3c_f {
// 		drop if missing(`var')
// 	}
// 	cls
//
// // regress electricity consumption on GDP:
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
// // Create a dataset where negatives are filled downwards:
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