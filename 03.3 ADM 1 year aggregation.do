/* This cleans all the subnational ADM1 GRP data and merges it with subnational VIIRS
and BM data */

/* First, load all the data ---------------------------------------------- */

// Mapping from [region --> GID_1]
// for India, Brazil, Indonesia, USA.
// (note that the geo-coding is not perfect. we are unable to map 30 regions to their respective GID_1 ADM-1s IDs.
import delimited "$raw_data/National Accounts/geo_coded_data/global_subnational_ntlmerged_woPHL.csv", varnames(1) clear
gduplicates drop
check_dup_id "region"
tempfile country_website_mapping
save `country_website_mapping'

// Subnational GRP data for India, Brazil, Indonesia, Australia, Philipines, and USA.
use "$raw_data/National Accounts/IND_PHL_USA_AUS_adm1_grp.dta", clear
destring GRP, replace
append using "$input/brazil_subnatl_grp.dta", force
append using "$input/india_subnatl_grp.dta", force
replace region = lower(region)
check_dup_id "region year"
gen source = "country website"
mmerge region using `country_website_mapping'
drop if _merge != 3 // 29 regions unable to be mapped; in particular, Philipines and Australian mapping was poor.
drop _merge note
check_dup_id "region year"
tempfile IND_PHL_USA_AUS
save `IND_PHL_USA_AUS'
clear

// Mapping OECD [regional_name --> GID_1] 
// note that ADM1 mapping might not be perfect. right now, we're missing some of India
use "$raw_data/National Accounts/geo_coded_data/oecd2_adm2NTL_map17feb22.dta", clear
keep NAME_0 NAME_1 GID_1 iso3c regional_name
rename *, lower
decode_vars, all
gduplicates drop
naomit
conv_ccode name_0
drop if iso!=iso3c
drop iso name_0

// import subnational GRP
mmerge iso3c regional_name using "$input/oecd_tl2.dta"
keep if _merge ==3 // !!!!!!! right now we're missing 60 ADM-1 regions, much of which is India
drop _merge
rename value GRP
rename regional_name region
rename iso3c iso3c_grp
keep iso3c_grp region gid_1 name_1 GRP year
gen source = "OECD"
tempfile grp_oecd
save `grp_oecd'
clear

/* VIIRS night lights */
use "$input/NTL_VIIRS_appended_cleaned_all.dta", clear
keep objectid iso3c gid_1 year month del_sum_pix del_sum_area
gcollapse (sum) del_sum_pix (mean) del_sum_area, by(objectid iso3c gid_1 year)
gcollapse (sum) del_sum_pix del_sum_area, by(iso3c gid_1 year)
label variable del_sum_pix "VIIRS (cleaned) sum of pixels"
label variable del_sum_area "VIIRS (cleaned) polygon area" 
tempfile viirs
save `viirs'
clear

/* Black Marble night lights */
use "$input/bm_adm1_year.dta", clear
drop pol_area
naomit
tempfile bm
save `bm'
clear

/* DMSP */
use "$input/dmsp_adm1_year.dta", clear
drop pol_area
naomit
tempfile dmsp
save `dmsp'
clear

/* Polygon Area */
use "$input/dmsp_adm1_year.dta", clear
keep gid_1 pol_area
naomit
gduplicates drop
check_dup_id "gid_1"
tempfile pol_area
save `pol_area'
clear

/* MERGE EVERYTHING! */
use `iibu'
append using `grp_oecd'
mmerge gid_1 year using `viirs'
mmerge gid_1 year using `dmsp'
mmerge gid_1 using `pol_area'

/* basically, one check is to make sure that the countries align -- they
don't, unfortunately  // !!!!!!! some were not geocoded accurately */
assert iso3c == iso3c_grp | mi(iso3c) | mi(iso3c_grp)
keep if iso3c == iso3c_grp | mi(iso3c) | mi(iso3c_grp)
drop iso3c
drop _merge
mmerge gid_1 year using `bm'
assert iso3c == iso3c_grp | mi(iso3c) | mi(iso3c_grp)
keep if iso3c == iso3c_grp | mi(iso3c) | mi(iso3c_grp)
drop iso3c
rename iso3c_grp iso3c
drop _merge

drop if mi(GRP) | mi(gid_1) | mi(year)

// drop if we got it directly from the country website (better than OECD data)
drop if (iso3c == "BRA" | iso3c == "IDN" | iso3c == "IND" | iso3c == "USA") & (source == "OECD")

// check duplicates
// check_dup_id "gid_1 year"
bys name_1 year: gen n = _N
// br if n>1 !!!!!! some were not geocoded accurately again!
keep if n==1

// collapse to OECD region level
gcollapse (sum) del_sum_pix del_sum_area sum_pix_bm sum_pix_dmsp_ad pol_area (mean) GRP, ///
	by(gid_1 iso3c year source)
rename gid_1 region

// remove fake zeros
foreach i in del_sum_pix del_sum_area sum_pix_bm sum_pix_dmsp_ad pol_area {
	replace `i' = . if `i' == 0
}

scatter pol_area del_sum_area

// create variables of interest
gen ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
gen ln_sum_pix_bm_area = ln(sum_pix_bm/pol_area)
gen ln_sum_pix_dmsp_ad_area = ln(sum_pix_dmsp_ad/pol_area)
create_logvars "GRP del_sum_pix sum_pix_bm sum_pix_dmsp_ad"
label variable ln_del_sum_pix_area "Log(VIIRS pixels/area)"
label variable ln_sum_pix_bm_area "Log(BM pixels/area)"
label variable ln_sum_pix_dmsp_ad_area "Log(DMSP pixels/area)"
label variable ln_GRP "Log(Gross Regional Product)"

// label the OECD variables
label_oecd iso3c

// change from "region" to "ADM1"
rename region ADM1

// create categorical variables
create_categ(ADM1 iso3c year)

// save:
save "$input/adm1_year_aggregation.dta", replace
.