// load data and do some checks
use "$input/NTL_VIIRS_appended_cleaned_all.dta", clear
assert abs(del_sum_area_new-sum_area)<0.1 | mi(del_sum_area_new-sum_area)
assert mi(sum_pix_new) if month!=1
gcollapse (sum) del_sum_pix sum_pix_new (mean) del_sum_area sum_area, by(year objectid iso3c)
save "$input/NTL_VIIRS_objectid_ann.dta", replace
gcollapse (sum) del_sum_pix sum_pix_new del_sum_area sum_area, by(year iso3c)

// have manually checked equivalence with
// iso3c_year_viirs_new.dta
save "$input/NTL_VIIRS_iso3c_ann.dta", replace

// produce 2 graphs - 1 for objectID-month level, 
// another for country-year level
foreach i in NTL_VIIRS_iso3c_ann NTL_VIIRS_objectid_ann {
	use "$input/`i'.dta", clear	
	gen del_sum_pix_area = del_sum_pix/del_sum_area
	gen sum_pix_area_new = sum_pix_new/sum_area
	label variable del_sum_pix_area "VIIRS cleaned pixels / area (monthly series)"
	label variable sum_pix_area_new "VIIRS pixels / area (annual series)"
	scatter del_sum_pix_area sum_pix_area_new
	gr export "$overleaf/scatter_VIIRS_products_`i'.pdf", replace
}
