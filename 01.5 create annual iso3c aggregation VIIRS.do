// Create annual ISO3C aggregation of VIIRS annual product:

// collapse by iso3c year:
use "$input/NTL_appended_cleaned.dta", clear
keep del_sum_pix sum_pix del_sum_area sum_area iso3c year month objectid
gcollapse (sum) del_sum_pix sum_pix (mean) del_sum_area sum_area, by(iso3c objectid year)

// are there any objectids that are completely excluded by removing 
// neg pixels?
br if abs(sum_area - del_sum_area ) >= 0.1
// yes -- one objectid in solomon islands is completely excluded

// collapse by year and country
gcollapse (sum) del_sum_pix sum_pix del_sum_area sum_area, by(iso3c year)

// make sure that across time, the polygon area remains the same
sort iso3c year
by iso3c:gen sum_area_L1 = sum_area[_n-1]
assert abs(sum_area_L1 - sum_area) < 1 if !mi(sum_area_L1)
br if iso3c == "AUS"
tempfile viirs1
save `viirs1'

// do the same for the annual product
use "$input/NTL_appended2_cleaned.dta", clear
rename iso3c_new iso3c
gcollapse (sum) sum_pix_new (mean) sum_area_new, by(iso3c objectid year)
gcollapse (sum) sum_pix_new        sum_area_new, by(iso3c          year)

// make sure that across time, the polygon area remains the same
sort iso3c year
by iso3c:gen sum_area_new_L1 = sum_area_new[_n-1]
br if !(abs(sum_area_new_L1 - sum_area_new) < 1 & !mi(sum_area_new_L1))
// ok, the annual product is kind of screwed up for some of 2014 & 2015

// but we merge anyways, knowing this:
mmerge iso3c year using `viirs1'
drop *L1 _merge

save "$input/iso3c_year_viirs_new.dta", replace

