// This file cleans VIIRS (i.e. creates a unified dataset with the negatives
// deleted for VIIRS. Here, NTL_appended denotes the monthly VIIRS nightlights
// data, while NTL_appended2 to denotes the annual VIIRS nightlights data. We
// noticed that some ADM2 regions had negative values for their pixel lumosity.
// This doesn't make sense, as you cannot have negative amounts of brightness,
// so we create a clean version of the VIIRS data by deleting the ADM2 regions
// that have negative lumosity. We call this variable del_sum_pix, where 'del'
// stands for 'deleted'. We continue to keep the original non-deleted
// 'non-clean' version of the nightlights data, under the name sum_pix.

foreach viirs_file_type in NTL_appended NTL_appended2 {
	
	use "$input/`viirs_file_type'.dta", clear

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
	rename (sum_pix pol_area) (sum_pix sum_area)
	tempfile ntl_raw
	save `ntl_raw'

	use `base_viirs'
	keep if !missing(sum_pix)
	// key difference between the cleaned and not cleaned VIIRS is that we
	// delete here.
	drop if sum_pix<0
	rename (sum_pix pol_area) (del_sum_pix del_sum_area)
	tempfile ntl_clean
	save `ntl_clean'
	
	// merge the cleaned and not-cleaned VIIRS (cleaned means that we delete
	// negatives)
	clear
	use `ntl_clean'
	mmerge iso3c objectid year month using `ntl_raw'
	drop _merge

	check_dup_id "objectid year month"

	// label variables
	label variable del_sum_area "VIIRS (cleaned) polygon area"
	label variable del_sum_pix "VIIRS (cleaned) sum of pixels"
	label variable sum_area "lights (raw) polygon area"
	label variable std_pix "VIIRS (raw) standard deviation of pixels"
	label variable sum_pix "VIIRS (raw) sum of pixels"

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

g diff_sum_area = sum_area/sum_area_new - 1
assert abs(diff_sum_area)<0.001 if (!missing(diff_sum_area) & !missing(sum_area))
drop diff_sum_area

foreach i in iso3c name_0 gid_1 name_1 gid_2 sum_area {
	replace `i' = `i'_new if missing(`i')
	drop `i'_new
}

save "$input/NTL_VIIRS_appended_cleaned_all.dta", replace

// We then take the two VIIRS data (monthly and annual) and aggregate that data
// to an annual country level. First, you have to aggregate to an ADM2 year
// level. And then, you have to aggregate to a country-year level. I did a check
// at the end, and it does seem like the annual product is missing some data in
// 2014 and 2015. This  doesn't matter too much, because in the end, we use the
// monthly product that we manually obtained, as well as the Black Marble
// version of nightlights, not the annual product. We mostly use the annual
// product as a validation that we've obtained the monthly product correctly.

// Create annual ISO3C aggregation of VIIRS product: -----------------

// get the VIIRS versions (annual product)
clear
input str70 datasets
	"$input/NTL_appended_cleaned.dta"
	"$input/NTL_appended2_cleaned.dta"
end
levelsof datasets, local(datasets)

tempfile viirs1 viirs2
local counter = 1
foreach data in `datasets' {

    // define the variables
    if ("`data'" == "$input/NTL_appended_cleaned.dta"){
        local area_vars sum_area del_sum_area
        local light_vars del_sum_pix sum_pix
    }
    else if ("`data'" == "$input/NTL_appended2_cleaned.dta"){
        local area_vars sum_area_new
        local light_vars sum_pix_new
    }

    use "`data'", clear

    // collapse by iso3c year:
    quietly capture rename iso3c_new iso3c
    keep `light_vars' `area_vars' iso3c year month objectid
    gcollapse (sum) `light_vars' (mean) `area_vars', by(iso3c objectid year)
    gcollapse (sum) `light_vars' `area_vars', by(iso3c year)

    // make sure that across time, the polygon area remains the same
	foreach i in `area_vars' {
		sort iso3c year
		by iso3c:gen `i'_L1 = `i'[_n-1]

		// the annual product is kind of screwed up for some of 2014 & 2015
		if ("`data'" == "$input/NTL_appended_cleaned.dta"){
			assert abs(`i'_L1 - `i') < 1 if !mi(`i'_L1)	
		}
    }

    local counter = `counter' + 1
    save `viirs`counter''
}

// merge:
clear
use `viirs2'
mmerge iso3c year using `viirs1'
drop *L1 _merge

save "$input/iso3c_year_viirs_new.dta", replace

// Create annual ISO3C aggregation of VIIRS monthly product:

// collapse by iso3c month:
use "$input/NTL_appended_cleaned.dta", clear
keep del_sum_pix sum_pix del_sum_area sum_area iso3c year month objectid
gcollapse (sum) del_sum_pix sum_pix del_sum_area sum_area, by(iso3c year month)
save "$input/iso3c_month_viirs.dta", replace

// CHECKS -----------------------------------------------------------------------

// make sure that across time, the polygon area remains the same
sort iso3c year month
by iso3c:gen sum_area_L1 = sum_area[_n-1]
assert abs(sum_area_L1 - sum_area) < 1 if !mi(sum_area_L1)

// compare polygon area with polygon area of other VIIRS aggregation
keep sum_area iso3c
gduplicates drop
tempfile areas
save `areas'
use "$input/iso3c_year_viirs_new.dta", clear
keep sum_area iso3c
rename sum_area other_sum_area
gduplicates drop
mmerge iso3c using `areas'
keep if _merge == 3
assert abs(sum_area - other_sum_area) < 1