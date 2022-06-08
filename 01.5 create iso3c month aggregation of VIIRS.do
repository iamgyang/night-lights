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