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
	
*** QUATERLY =================================================================

***	Import Oxford Econ Quarterly --------------------------------------------

*** Import Dataset.
	use "$hf_input/National Accounts/oxford_econ_full.dta", clear
	keep if indicator == "GDP, real, LCU"
	
*** this indicator seems to have the most observations
	keep if indicator_code == "GDP_QTR" 
	keep location units scale period x* base_year_price location_code
	
*** Pivot to long Oxford Dataset
	rename location_code iso3c
	reshape long x, i(iso3c scale period) j(year)
	sort iso3c year period
	
*** Convert everything to millions. 
*** (if 'scale' says billions, divide the values by 1000)
	gen bil = 1000 if strpos(scale, "Billion")
	replace bil = 1 if bil ==.
	replace x = x * bil
	rename x ox_rgdp_lcu
	label variable ox_rgdp_lcu "Oxford Economics Real GDP in LCU (millions)"
		
*** Clean quarter variable
	moss period, match("([0-9]+)")  regex
	keep iso3c period year ox_rgdp_lcu _match1 scale
	rename _match1 quarter
	destring quarter, replace
	drop period

*** Get all combinations of country code, year, and quarter:
	fillin iso3c year quarter
	drop _fillin
	rename scale base_year_oxford
	tempfile ox_econ_data2
	save `ox_econ_data2'
		
*** Import IMF quarterly real GDP --------------------------------------------

*** Import dataset
	import excel "$hf_input/National Accounts/imf_national_gdp.xlsx", ///
	sheet("Nominal Quarterly") cellrange(B7:AH85) clear

*** replace first row to be the variable names
	foreach var of varlist * {
	  replace `var' = "" if `var'=="..."
	  rename `var' `=strtoname("x"+`var'[1])'
	  
	}

*** drop 1st row
	drop in 1
	destring x*, replace

*** rename everything to lower
	rename *, lower
	rename xcountry country

*** get iso3c codes:
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
	
***	wide to long:
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
	
*** Convert from nominal to real GDP

*** get GDP deflator data:
	wbopendata, language(en – English) indicator(NY.GDP.DEFL.ZS) long clear
	keep countrycode year ny_gdp_defl_zs
	drop if ny_gdp_defl_zs ==.
	rename (countrycode ny_gdp_defl_zs) (iso3c deflator)
	mmerge iso3c year using `quarterly_nominal_gdp'
	keep if inlist(_m, 2,3)
	
/*  make the base year 2016: (won't really make a difference if all we do is 
	growth regressions, but if we do something else, want to have this comparable) */
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

*** done with cleaning GDP data:
	save "$hf_input/imf_real_gdp.dta", replace
	use "$hf_input/imf_real_gdp", clear
	
	gen year = year(dofq(yq))
	gen quarter = quarter(dofq(yq))
	drop yq
	fillin iso3c year quarter
	drop _fillin
	mmerge iso3c year quarter using `ox_econ_data2'
	drop _m

*** make sure that we have no duplicated ISO3c, year, and quarters:
	preserve
	sort iso3c year quarter
	keep iso3c year quarter
	duplicates tag iso3c year quarter, gen (dup_id_cov)
	assert dup_id_cov==0
	restore
	
*** export to dta:
	sort iso3c year quarter
	label variable nom_gdp "IMF nominal GDP, quarterly, national." 
	label variable rgdp "IMF real GDP, quarterly, national." 
	save "$hf_input/imf_oxf_GDP_quarter.dta", replace
	
*** merge GDP measures with NTL measures on a quarterly basis
	tempfile ox_imf_data
	save `ox_imf_data'
	
*** ANNUAL =================================================================

*** Import IMF WEO dataset on real GDP (LCU) -------------------------------
	import delimited "$hf_input/National Accounts/WEOApr2021all.txt", clear
	keep if subjectdescriptor == "Gross domestic product, constant prices"
	keep if units == "National currency"
	rename (v10 v11 v12 v13 v14 v15 v16 v17 v18 v19 v20 v21 v22 v23 v24 v25 v26 v27 v28 v29 v30 v31 v32 v33 v34 v35 v36 v37 v38 v39 v40 v41 v42 v43 v44 v45 v46 v47 v48 v49 v50 v51 v52 v53 v54 v55 v56) (x1980 x1981 x1982 x1983 x1984 x1985 x1986 x1987 x1988 x1989 x1990 x1991 x1992 x1993 x1994 x1995 x1996 x1997 x1998 x1999 x2000 x2001 x2002 x2003 x2004 x2005 x2006 x2007 x2008 x2009 x2010 x2011 x2012 x2013 x2014 x2015 x2016 x2017 x2018 x2019 x2020 x2021 x2022 x2023 x2024 x2025 x2026)
	keep x2012 x2013 x2014 x2015 x2016 x2017 x2018 x2019 x2020 x2021 x2022 iso
	destring x*, replace ignore(`","', illegal) force float
	rename iso iso3c
	reshape long x, i(iso3c) j(year)
	rename x imf_rgdp_lcu
	label variable imf_rgdp_lcu "IMF WEO GDP, constant prices, LCU, BILLIONS"
	tempfile weo_levels
	save `weo_levels'

*** check there are no duplicated country-years
	preserve
	keep iso3c year
	duplicates tag iso3c year, gen (dup_id_cov)
	assert dup_id_cov==0
	restore
	
*** Import PWT dataset on real GDP (PPP) -----------------------------------
	use "$hf_input/National Accounts/pwt100.dta", clear
	keep rgdpna year countrycode
	drop if rgdpna == . 
	drop if year < 2012
	rename countrycode iso3c
	tempfile pwt
	save `pwt'
	
*** check there are no duplicated country-years
	preserve
	keep iso3c year
	duplicates tag iso3c year, gen (dup_id_cov)
	assert dup_id_cov==0
	restore
	
*** Merge IMF and PWT real GDP -----------------------------------------------
	mmerge iso3c year using `weo_levels'
	drop _m
	rename rgdpna pwt_rgdpna
	save "$hf_input/imf_pwt_GDP_annual.dta", replace
	
*** Import WDI dataset on real GDP (LCU) -------------------------------------
	
	clear
	wbopendata, clear nometadata long indicator(NY.GDP.MKTP.KN) year(2000:2021)
	drop if regionname == "Aggregates"
	keep countrycode year ny_gdp_mktp_kn
	rename (countrycode ny_gdp_mktp_kn) (iso3c WDI)
	fillin iso3c year
	drop _fillin
	sort iso3c year
	tempfile wdi_gdp
	save `wdi_gdp'
	
	use "$hf_input/imf_pwt_GDP_annual.dta", clear
	mmerge iso3c year using `wdi_gdp'
	drop _m
	
	*** make sure we only have 1 country-year pairs:
		preserve
		sort iso3c year
		keep iso3c year
		duplicates tag iso3c year, gen (dup_id_cov)
		assert dup_id_cov==0
		restore
	
	save "$hf_input/imf_pwt_GDP_annual.dta", replace

*** Merge all data with NTL data ---------------------------------------------
	use "$hf_input/ntl_cty_agg.dta", clear
	rename quart quarter
	mmerge year quarter iso3c using `ox_imf_data'
	drop _m
	mmerge year iso3c using "$hf_input/imf_pwt_GDP_annual.dta"
	drop _m
	
*** drop IMF WEO estimates of future GDP growth
	drop if year > 2021 | quarter == .
	fillin iso3c year quarter
	table _f
	drop _f
	save "$hf_input/imf_pwt_oxf_ntl.dta", replace

