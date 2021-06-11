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
	
*** CHANGE THIS!! --- Do we want to install user-defined functions? --------
	loc install_user_defined_functions "No"
	
*** Install user-defined functions: ----------------------------------------
	if ("`install_user_defined_functions'" == "Yes") {
		foreach i in rangestat wbopendata kountry mmerge outreg2 somersd asgen moss {
			ssc install `i'
		}
	}

*** Comparison between Oxford & IMF Fiscal Monitor dataset -----------------
*** Import dataset.
	use "$hf_input/imf_oxf_GDP_quarter.dta", clear
	
*** Drop numbers for which oxford and IMF don't have data
*** For each iso3c, tag the most recent year and most recent quarter.
	drop if rgdp==. | ox_rgdp_lcu==.
	bysort iso3c: egen max_yr = max(year)
	
*** Make sure that we have 4 quarters for each year and country
	preserve
	gen counter = 1
	collapse (sum) counter, by(iso3c year)
	assert counter == 4
	restore
	
*** Collapse by summing across year and ISO3C
	collapse (sum) rgdp ox_rgdp_lcu, by(iso3c year)
	
*** check: Oxford data should match IMF's data
	foreach i in rgdp ox_rgdp_lcu {
		gen ln_`i' = ln(`i')
	}
	twoway (scatter ln_rgdp ln_ox_rgdp_lcu), ytitle("IMF Log Quarterly real GDP Level (LCU)") xtitle("Oxford Log Quarterly real GDP Level (LCU)") title("GDP Levels") caption("Source: IMF, Oxford Economics")
	graph export "$hf_input/scatter_imf_oxf_quart_gdp_levels.png", replace
	regress ln_rgdp ln_ox_rgdp_lcu
	
*** restore, and find the AVERAGE growth from 2013Q1 to most recent year
	keep iso3c rgdp year ox_rgdp_lcu
	reshape wide rgdp ox_rgdp_lcu, i(iso3c) j(year)

*** we add 1 because we are considering growth from the 2013 to 2019, so we 
*** have 2019-2013 years in total.
	gen avg_gr_ox = (ox_rgdp_lcu2019/ox_rgdp_lcu2013)^(1/(2019-2013)) -1
	gen avg_gr_imf = (rgdp2019/rgdp2013)^(1/(2019-2013)) -1
	twoway (scatter avg_gr_imf avg_gr_ox), ytitle("IMF Average Geometric Growth 2013-2019") xtitle("Oxford Average Geometric Growth 2013-2019") title("Average Growth (2013-2019)") caption("Source: IMF, Oxford Economics")
	graph export "$hf_input/scatter_imf_oxf_quart_gdp_growth.png", replace
	
*** Find the stdev of the difference between the average growth of oxford and imf
	gen diff = abs(avg_gr_ox - avg_gr_imf)
	collapse (mean) avg_gr_imf avg_gr_ox diff
	graph bar (asis) avg_gr_imf avg_gr_ox diff, blabel(bar) legend(order(1 "IMF" 2 "Oxford" 3 "Standard Deviation of Difference")) scheme(s2color8) ytitle("") title("Average Annual Growth (2013-2020) vs. Standard Deviation") caption("Source: IMF, Oxford Economics")
	graph export "$hf_input/bar_imf_oxf_quart_gdp_gr_stdev.png", replace
	
*** Comparison between PWT and IMF WEO dataset ----------------------------

*** Import dataset
	use "$hf_input/imf_pwt_GDP_annual.dta", clear
	
*** check: PWT data should match IMF's data
	foreach i in pwt_rgdpna imf_rgdp_lcu {
		gen ln_`i' = ln(`i')
	}
	twoway (scatter ln_imf_rgdp_lcu ln_pwt_rgdpna), ytitle("IMF Log Annual real GDP Level (LCU)") xtitle("PWT Log Annual real GDP Level (PPP)") title("GDP Levels") caption("Source: IMF, PWT")
	graph export "$hf_input/scatter_imf_pwt_annu_gdp_levels.png", replace
	encode iso3c, gen(iso3c_factor)
	regress ln_imf_rgdp_lcu ln_pwt_rgdpna i.iso3c_factor
	drop ln*
	
*** keep 2012 and 2020
	keep if inlist(year, 2012, 2019)
	drop if pwt_rgdpna==. | imf_rgdp_lcu==.
	
*** get implied growth rate for these yrs
	drop WDI
	reshape wide pwt_rgdpna imf_rgdp_lcu, i(iso3c) j(year)
	gen avg_gr_pwt = (pwt_rgdpna2019/pwt_rgdpna2012)^(1/(2019-2012)) -1
	gen avg_gr_imf = (imf_rgdp_lcu2019/imf_rgdp_lcu2012)^(1/(2019-2013+1)) -1
	twoway (scatter avg_gr_imf avg_gr_pwt), ytitle("IMF Average Geometric Growth 2012-2019") xtitle("PWT Average Geometric Growth 2012-2019") title("Average Growth (2012-2019)") caption("Source: IMF, PWT")
	graph export "$hf_input/scatter_imf_pwt_annu_gdp_growth.png", replace
	
*** Find the stdev of the difference between the average growth of PWT and imf
	gen diff = abs(avg_gr_pwt - avg_gr_imf)
	collapse (mean) avg_gr_imf avg_gr_pwt diff
	graph bar (asis) avg_gr_imf avg_gr_pwt diff, blabel(bar) legend(order(1 "IMF" 2 "PWT" 3 "Standard Deviation of Difference")) scheme(s2color8) ytitle("") title("Average Annual Growth (2012-2019) vs. Standard Deviation") caption("Source: IMF, PWT")
	graph export "$hf_input/bar_imf_pwt_annu_gdp_gr_stdev.png", replace








































