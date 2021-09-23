
*** Create a monthly NTL - GDP dataset: =======================================
	use "$input/NTL_appended2.dta", clear
	capture quietly drop year
	gen year = year(date2)
	gen month = month(date2)
	gen quarter = quarter(date2)
	
/* make sure that the number of rows at the beginning is the same as the 
number of rows at the end */
	gen n = _n
	egen n_row_before = max(n)
	drop n

*** Merge with GDP data:
	mmerge iso3c year using "$input/imf_pwt_GDP_annual.dta"
//  	keep if inlist(_merge, 1, 3)
	drop _merge

	mmerge iso3c year quarter using "$input/imf_oxf_GDP_quarter.dta"
//  	keep if inlist(_merge, 1, 3)
	drop _merge
	
	rename (nom_gdp rgdp) (imf_quart_nom_gdp imf_quart_rgdp)
	
	preserve
	keep if objectid != ""
 	duplicates tag objectid time, gen(dup)
 	assert dup == 0
 	drop dup
	restore

// 	check: IF object ID is empty, then there should be no duplicate year-iso3c-quarters

	preserve
	keep if objectid == ""
	bysort year iso3c quarter: gen dup = _n
	assert dup == 1
	restore
	
	save "$input/NTL_GDP_month_ADM2_new_VIIRS.dta", replace
	