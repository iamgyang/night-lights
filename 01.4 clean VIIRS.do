// This file cleans VIIRS (i.e. creates a unified dataset with the negatives deleted for VIIRS

foreach viirs_file_type in NTL_appended NTL_appended2 {
	use "$input/`viirs_file_type'.dta", clear
// 	gen n = _n
// 	keep if n <= 10
// 	drop n
	
	// get ID values for the date: year, month, and quarter:
	capture quietly drop year
	gen year = year(date2)
	gen month = month(date2)
	gen quarter = quarter(date2)
	keep objectid year month quarter iso3c name_0 gid_1 name_1 gid_2 ///
	sum_pix std_pix pol_area
	tempfile base_viirs
	save `base_viirs'

	use `base_viirs'
	keep if !missing(sum_pix)
	rename (sum_pix pol_area) (del_sum_pix del_sum_area)
	tempfile ntl_raw
	save `ntl_raw'

	use `base_viirs'
	keep if !missing(sum_pix)
	// key difference between the cleaned and not cleaned VIIRS is that we delete here.
	drop if sum_pix<0
	rename (sum_pix pol_area) (sum_pix sum_area)
	tempfile ntl_clean
	save `ntl_clean'
	
	// merge the cleaned and not-cleaned VIIRS (cleaned means that we delete negatives)
	clear
	use `ntl_clean'
	mmerge iso3c objectid year month using `ntl_raw'
	drop _merge

	check_dup_id "objectid year month"

	// per area variables
	gen del_sum_pix_area = del_sum_pix / del_sum_area
	gen sum_pix_area = sum_pix / sum_area

	// label variables
	label variable del_sum_area "VIIRS (cleaned) polygon area"
	label variable del_sum_pix "VIIRS (cleaned) sum of pixels"
	label variable sum_area "lights (raw) polygon area"
	label variable std_pix "VIIRS (raw) standard deviation of pixels"
	label variable del_std_pix "VIIRS (cleaned) standard deviation of pixels"
	label variable sum_pix "VIIRS (raw) sum of pixels"
	label variable sum_pix_area "VIIRS (raw) sum of pixels / area"
	label variable del_sum_pix_area "VIIRS (cleaned) pixels / area"

	// list all variables except ID variables & rename them
	ds
	macro drop varlist
	local varlist `r(varlist)'
	local excluded objectid year month quarter
	local varlist : list varlist - excluded 
	if ("`viirs_file_type'" == "NTL_appended2") {
		foreach i in `varlist' {
			loc lab: variable label `i'
			rename `i' `i'_new
			label variable `i'_new "`lab' New Ann. Series"
		}
	}
	
	// checks
	foreach i in objectid year month quarter {
		assert !missing(`i')
	}
	check_dup_id "objectid year month quarter"
	
	save "$input/`viirs_file_type'_cleaned.dta", replace
}

use "$input/NTL_appended_cleaned.dta", clear
mmerge objectid year month quarter using "$input/NTL_appended2_cleaned.dta"
drop _merge
check_dup_id "objectid year month quarter"

destring std_pix, replace force
foreach i in iso3c name_0 gid_1 name_1 gid_2 sum_area {
	drop `i'_new
}

save "$input/NTL_VIIRS_appended_cleaned_all.dta", replace

































