// load datasets --------------------------------------------------------------

// regional GRP at ADM2 level from the OECD
	import delimited "$raw_data/National Accounts/oecd_region_TL3_2022-06-08.csv", encoding(UTF-8) clear
	rename *, lower
	keep if measure == "      Millions National currency, constant prices, base year 2015"
	keep if tl == 3
	drop if flags == "Estimated value"
	assert meas == "REAL_PR"
	assert indicator == "Regional GDP"
	assert powercode == "Millions"
	assert year == time
	assert !mi(time)
	assert !mi(year)
	keep reg_id value year unit
	tempfile grp
	save `grp'

// geocoded Khare AMD2 ObjectID <--> OECD regional ID
	// note: the name of this file is BM_adm2... BUT, I just use it for the geocoded region ID -- ObjectID mapping 
	use "$raw_data/Black Marble NTL/bm_ADM2_05-09-2022.dta", clear 
	rename *, lower
	keep objectid reg_id iso3c country
	gduplicates drop
	conv_ccode country
	// there are around 20 Object IDs where they are mapped to the wrong country; we delete these, as these are geocoding errors.
	drop if iso != iso3c 
	// one OECD regional ID can have multiple Object IDs, but one Object ID cannot have multiple regional IDs
	check_dup_id "reg_id" 
	tempfile map_objectid
	save `map_objectid'

// black marble
	use "$input/bm_adm2_month.dta", clear
	keep objectid sum_pix_bm year month
	gcollapse (sum) sum_pix_bm, by(objectid year)
	check_dup_id "objectid year"
	tempfile bm
	save `bm'

// dmsp
	use "$input/dmsp_adm2_year.dta", clear
	keep objectid year sum_pix_dmsp_ad
	check_dup_id "objectid year"
	tempfile dmsp
	save `dmsp'

// polygon area, iso3c, etc.
	use "$input/dmsp_adm2_year.dta", clear
	keep objectid pol_area iso3c
	gduplicates drop
	check_dup_id "objectid"
	tempfile pol_area
	save `pol_area'

// merge ----------------------------------------------------------------------
clear

// use our Gross Regional Product data
use `grp'

// merge with the map from OECD ADM2 regional ID --> Khare ADM2 Object ID
mmerge reg_id using `map_objectid'

// there were ~30 regions that were not able to accurately geocoded to an objectID
drop if mi(objectid)

// as a further geo-coding check, make sure that WHEN and IF a region-ID got mapped to the same object-ID, that the units of GDP are the same (i.e. they should be all within the same country). There are 20 rows where this is not the case (all within the same object-ID 5de70a1a84, which we delete)
bys objectid year: gen L_unit = unit[_n-1]
br if L_unit != unit & !mi(L_unit)
drop if objectid == "5de70a1a84"
drop L_unit unit
assert !mi(objectid)
assert !mi(iso3c)
gcollapse (sum) value, by(objectid year)

mmerge objectid year using `bm'
mmerge objectid year using `dmsp'
mmerge objectid using `pol_area'
drop _merge
rename objectid ADM2
rename value GRP

// further data editing ------------------------------------------------------

check_dup_id "ADM2 year"
assert !mi(pol_area)

// create variables of interest
label variable GRP "Gross Regional Product"
label variable sum_pix_bm "BM pixels"
label variable sum_pix_dmsp_ad "DMSP pixels"
foreach i in sum_pix_bm sum_pix_dmsp_ad {
	gen `i'_area = `i' / pol_area
	loc lab: variable label `i'
	label variable `i'_area "`lab'/area"
	create_logvars "`i'_area"
}
create_logvars "GRP"

// create categorical variables
create_categ(ADM2 iso3c year)
assert mi(cat_iso3c) if mi(iso3c)

// save:
save "$input/adm2_year_aggregation.dta", replace
.
