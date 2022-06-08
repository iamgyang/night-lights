// This file takes the two VIIRS data (monthly and annual) and aggregates that
// data to an annual country level. First, you have to aggregate to an ADM2 year
// level. And then, you have to aggregate to a country-year level. I did a check
// at the end, and it does seem like the annual product is missing some data in
// 2014 and 2015. This  doesn’t matter too much, because in the end, we use the
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

