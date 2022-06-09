/* This cleans all the subnational ADM1 GRP data and merges it with subnational VIIRS
and BM data */

/* First, load all the data ---------------------------------------------- */

// A) COUNTRY WEBSITES ----
// Mapping [region --> GID_1]
// for India, Brazil, Indonesia, USA country website.
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
drop _merge note region
check_dup_id "gid_1 year"
tempfile IND_BRA_USA_IDN
save `IND_BRA_USA_IDN'
clear

// B) OECD ----
// Mapping [regional_name --> GID_1] 
// for all of OECD
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

// Subnational GRP data for all of OECD
mmerge iso3c regional_name using "$input/oecd_tl2.dta"
keep if _merge ==3 // right now we're missing 60 ADM-1 regions, much of which is India
drop _merge
rename value GRP
rename regional_name region
rename iso3c iso3c_grp
keep iso3c_grp region gid_1 name_1 GRP year
check_dup_id "iso3c_grp region year" // multiple regions map to a single GID_1, so we have to collapse
gcollapse (sum) GRP, by(gid_1 iso3c_grp year)
gen source = "OECD"
check_dup_id "gid_1 year"
tempfile grp_oecd
save `grp_oecd'
clear

/* Black Marble night lights */
use "$input/bm_adm1_year.dta", clear
drop pol_area
naomit
tempfile bm
check_dup_id "gid_1 year"
save `bm'
clear

/* DMSP */
use "$input/dmsp_adm1_year.dta", clear
drop pol_area
naomit
tempfile dmsp
save `dmsp'
check_dup_id "gid_1 year"
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
use `IND_BRA_USA_IDN'
append using `grp_oecd'
mmerge gid_1 year using `dmsp'
mmerge gid_1 using `pol_area'

assert !mi(gid_1)
assert !mi(year)

/* basically, one check is to make sure that the countries align -- they
don't, unfortunately  // !!!!!!! some were not geocoded accurately */
assert iso3c == iso3c_grp | mi(iso3c) | mi(iso3c_grp)
keep if iso3c == iso3c_grp | mi(iso3c) | mi(iso3c_grp)
replace iso3c_grp = iso3c if mi(iso3c_grp)
replace iso3c_grp = "XKX" if iso3c_grp == "XKO"
drop iso3c _merge
mmerge gid_1 year using `bm'
assert iso3c == iso3c_grp | mi(iso3c) | mi(iso3c_grp)
keep if iso3c == iso3c_grp | mi(iso3c) | mi(iso3c_grp)
replace iso3c_grp = iso3c if mi(iso3c_grp)
drop name_1 iso3c
rename iso3c_grp iso3c
drop _merge
drop if mi(GRP) | mi(gid_1) | mi(year)

// drop if we got it directly from the country website (better than OECD data)
drop if (iso3c == "BRA" | iso3c == "IDN" | iso3c == "IND" | iso3c == "USA") & (source == "OECD")

// check duplicates
check_dup_id "gid_1 year"
assert !mi(iso3c)
assert source != "OECD" if iso3c == "BRA" | iso3c == "IDN" | iso3c == "IND" | iso3c == "USA"

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

// save:
save "$input/adm1_year_aggregation.dta", replace
.