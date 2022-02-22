// Subnational GRP regressions (EU): ---------------------------------------

// get WB statistical quality indicators:
use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear
keep wbdqcat_3 iso3c
gduplicates drop
naomit
tempfile wb_stat_capacity
save `wb_stat_capacity'

// get Europe regional GDP variable and generate categorical variables and log variables
use "$raw_data/National Accounts/geo_coded_data/global_subnational_ntlmerged_woPHL.dta", clear
encode country, gen( cat_iso3c )
gen yr = string(year)
encode yr, gen(cat_year)
drop yr
create_logvars "del_sum_pix del_sum_pix_area gdp"
naomit
conv_ccode country
replace iso = "CZE" if country == "Czechia"
rename iso iso3c

// merge the statistical capacity numbers:
mmerge iso3c using `wb_stat_capacity'
naomit
drop _merge
encode wbdqcat_3, gen(cat_wbdqcat_3)

// run regressions 
rename ln_gdp ln_WDI

// ok, this is going to be messy code, but I'm just adding another function here 
// that is basically the same one as above, but without WB statistical capacity

// run regressions
gr_lev_reg, levels outfile("$overleaf/NUTS_regression.tex") ///
	dep_vars(ln_del_sum_pix_area) ///
	abs_vars(cat_iso3c cat_year)
	
// make graphs
rename ln_WDI ln_gdp
label variable ln_del_sum_pix "Log Sum of Pixels"
label variable ln_gdp "Log GDP"
label variable ln_del_sum_pix_area "Log Sum of Pixels/Area"
sepscatter ln_gdp ln_del_sum_pix, mc(red blue) ms(Oh + ) separate(country) legend(size(*0.5) symxsize(*5) position(0) bplacement(nwest) region(lwidth(none)))
gr export "$overleaf/scatter_NUTS_log_log_pixel_gdp.pdf", replace
sepscatter ln_gdp ln_del_sum_pix_area, mc(red blue) ms(Oh + ) separate(country) legend(size(*0.5) symxsize(*5) position(0) bplacement(nwest) region(lwidth(none)))
gr export "$overleaf/scatter_NUTS_log_log_pixel_gdp_area.pdf", replace


// Subnational GRP regressions (EU - PART 2): -------------------------------

use "$raw_data/National Accounts/geo_coded_data/adm2nuts_map_clean_11feb22.dta", clear
keep OBJECTID GID_0 country GID_1 GID_2 year nuts_gdp
rename *, lower
decode_vars, all
conv_ccode country
replace iso = "MKD" if country == "NORTH MACEDONIA" 
replace iso = "CZE" if country == "CZECHIA" 
rename iso iso3c
rename (nuts_gdp year ) (GRP year)
destring GRP year, replace
tempfile NUTS_data
save `NUTS_data'
clear

use "$input/NTL_VIIRS_appended_cleaned_all.dta", clear
gcollapse (sum) del_sum_pix (mean) del_sum_area, by(objectid iso3c gid_1 gid_2 year) // aggregate across space
mmerge objectid gid_1 gid_2 year using `NUTS_data'
drop if mi(GRP) | mi(del_sum_pix)
assert _merge == 3
drop _merge


// merge with night lights
mmerge iso3c gid_1 gid_2 year using `NUTS_data'
keep if _merge == 3
check_dup_id "iso3c gid_1 gid_2 year"
drop _merge

// Ireland, France, and Lithuania have some problems; parth to re-geocode
conv_ccode country
drop if iso3c != iso

// create variables of interest
gen ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
gen ln_GRP = ln(GRP)
label variable ln_del_sum_pix_area "Log(VIIRS pixels/area)"
label variable ln_GRP "Log(Gross Regional Product)"

// graph:
sepscatter ln_del_sum_pix_area ln_GRP, mc(red blue green purple) separate(iso3c) legend(size(*0.5) symxsize(*5) position(0) bplacement(nwest) region(lwidth(none)))
gr export "$overleaf/scatter_GRP_log_log_subnatl_NUTS.pdf", replace

// regressions
create_categ(region year)

tempfile full_subnatl_grp
save `full_subnatl_grp'
est clear
use `full_subnatl_grp'

// log GDP ~ log lights
rename ln_del_sum_pix_area ln_del_sum_pix_area
eststo: reghdfe ln_GRP ln_del_sum_pix_area, absorb(cat_region cat_year) vce(cluster cat_region)
estadd local NC `e(N_clust)'
local y= round(`e(r2_a_within)', .001)
estadd local WR2 `y'
estadd local AGG "ADM1"

// log GDP ~ log lights for the same countries at a country level
gcollapse (sum) GRP del_sum_pix del_sum_area, by(iso3c year)
create_categ(iso3c year)
gen ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
gen ln_GRP = ln(GRP)
label variable ln_del_sum_pix_area "Log(VIIRS pixels/area)"
label variable ln_GRP "Log(Gross Regional Product)"
eststo: reghdfe ln_GRP ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
estadd local NC `e(N_clust)'
local y= round(`e(r2_a_within)', .001)
estadd local WR2 `y'
estadd local AGG "Country"

// export results into a tex file
esttab using "$overleaf/subnatl_reg_GRP_EU.tex", replace f  ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
label booktabs nomtitle nobaselevels collabels(none) ///
scalars("NC Number of Groups" "WR2 Adjusted Within R-squared" "AGG Aggregation Level") ///
sfmt(3) ///
mgroups("BRA IDN IND" "BRA IDN IND USA", pattern(1 0 1 0) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span ///
erepeat(\cmidrule(lr){@span})) drop(_cons)

// Subnational GRP regressions (non-EU): ------------------------------------

// import subnational GRP data
use "$raw_data/National Accounts/geo_coded_data/global_subnational_ntlmerged_woPHL.dta", clear
keep year region GRP iso3c_x gid_1 name_1
rename iso3c_x iso3c
tempfile grp_subnatl
save `grp_subnatl'

// clean night lights (only VIIRS cleaned version)
use "$input/NTL_VIIRS_appended_cleaned_all.dta", clear
keep objectid iso3c gid_1 year month del_sum_pix del_sum_area
gcollapse (sum) del_sum_pix (mean) del_sum_area, by(objectid iso3c gid_1 year)
gcollapse (sum) del_sum_pix del_sum_area, by(iso3c gid_1 year)
label variable del_sum_pix "VIIRS (cleaned) sum of pixels"
label variable del_sum_area "VIIRS (cleaned) polygon area" 

// merge with night lights
mmerge iso3c gid_1 year using `grp_subnatl'
keep if _merge == 3
check_dup_id "iso3c gid_1 year"
drop _merge

// create variables of interest
gen ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
gen ln_GRP = ln(GRP)
label variable ln_del_sum_pix_area "Log(VIIRS pixels/area)"
label variable ln_GRP "Log(Gross Regional Product)"

// graph:
sepscatter ln_del_sum_pix_area ln_GRP, mc(red blue green purple) separate(iso3c) legend(size(*0.5) symxsize(*5) position(0) bplacement(nwest) region(lwidth(none)))
gr export "$overleaf/scatter_GRP_log_log_subnatl_global.pdf", replace

// regressions
create_categ(region year)

tempfile full_subnatl_grp
save `full_subnatl_grp'

est clear
foreach i in "drop-US" "not drop US" {

clear
use `full_subnatl_grp'

if "`i'" == "drop-US" {
	drop if iso3c == "USA"
	keep if iso3c == "IND"
}

// log GDP ~ log lights
rename ln_del_sum_pix_area ln_del_sum_pix_area
eststo: reghdfe ln_GRP ln_del_sum_pix_area, absorb(cat_region cat_year) vce(cluster cat_region)
estadd local NC `e(N_clust)'
local y= round(`e(r2_a_within)', .001)
estadd local WR2 `y'
estadd local AGG "ADM1"

// log GDP ~ log lights for the same countries at a country level
gcollapse (sum) GRP del_sum_pix del_sum_area, by(iso3c year)
create_categ(iso3c year)
gen ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
gen ln_GRP = ln(GRP)
label variable ln_del_sum_pix_area "Log(VIIRS pixels/area)"
label variable ln_GRP "Log(Gross Regional Product)"
eststo: reg ln_GRP ln_del_sum_pix_area
estadd local NC `e(N_clust)'
local y= round(`e(r2_a_within)', .001)
estadd local WR2 `y'
estadd local AGG "Country"
}

// export results into a tex file
esttab using "$overleaf/subnatl_reg_GRP.tex", replace f  ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
label booktabs nomtitle nobaselevels collabels(none) ///
scalars("NC Number of Groups" "WR2 Adjusted Within R-squared" "AGG Aggregation Level") ///
sfmt(3) ///
mgroups("IND" "BRA IDN IND USA", pattern(1 0 1 0) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span ///
erepeat(\cmidrule(lr){@span})) drop(_cons)

// Subnational GRP regressions (all OECD) ------------------------------------------------------

// import subnational map data
use "$raw_data/National Accounts/geo_coded_data/oecd3_adm2NTL_map17feb22.dta", clear
keep OBJECTID iso3c regional_name reg_2
rename *, lower
decode_vars objectid

// import subnational GRP
mmerge iso3c regional_name reg_2 using "$input/oecd_tl3.dta"
keep if _merge ==3 // !!!!!!! some were not geocoded accurately
assert _merge == 3
drop _merge
rename iso3c iso3c_grp
rename value GRP
rename regional_name region
tempfile grp_subnatl
save `grp_subnatl'

// clean night lights (only VIIRS cleaned version)
use "$input/NTL_VIIRS_appended_cleaned_all.dta", clear
keep objectid iso3c year month del_sum_pix del_sum_area
gcollapse (sum) del_sum_pix (mean) del_sum_area, by(objectid iso3c year)
rename iso3c iso3c_ntl

// merge with night lights
mmerge objectid year using `grp_subnatl'
keep if _merge == 3
drop _merge
// assert iso3c_ntl == iso3c_grp // !!!!!!! some were not geocoded accurately
drop if iso3c_ntl != iso3c_grp 
rename iso3c_grp iso3c
// check_dup_id "objectid iso3c year" // !!!!! something is wrong here? each objectid gets repeated?

// collapse to OECD region level
gcollapse (sum) del_sum_pix del_sum_area (mean) GRP, by(region reg_2 iso3c year)

// create variables of interest
gen ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
gen ln_GRP = ln(GRP)
label variable ln_del_sum_pix_area "Log(VIIRS pixels/area)"
label variable ln_GRP "Log(Gross Regional Product)"

// graph:
sepscatter ln_del_sum_pix_area ln_GRP, mc(red blue green purple) separate(iso3c) legend(size(*0.5) symxsize(*5) position(0) bplacement(nwest) region(lwidth(none)))
gr export "$overleaf/scatter_GRP_log_log_subnatl_oecd.pdf", replace

// regressions
create_categ(region year)

tempfile full_subnatl_grp
save `full_subnatl_grp'

// clear regression estimates
est clear

// log GDP ~ log lights
eststo: reghdfe ln_GRP ln_del_sum_pix_area, absorb(cat_region cat_year) vce(cluster cat_region)
estadd local NC `e(N_clust)'
local y= round(`e(r2_a_within)', .001)
estadd local WR2 `y'
estadd local AGG "ADM1"

// log GDP ~ log lights, same countries @ COUNTRY level
gcollapse (sum) GRP del_sum_pix del_sum_area, by(iso3c year)
create_categ(iso3c year)
gen ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
gen ln_GRP = ln(GRP)
label variable ln_del_sum_pix_area "Log(VIIRS pixels/area)"
label variable ln_GRP "Log(Gross Regional Product)"
eststo: reghdfe ln_GRP ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
estadd local NC `e(N_clust)'
local y= round(`e(r2_a_within)', .001)
estadd local WR2 `y'
estadd local AGG "Country"

// export results into a tex file
esttab using "$overleaf/subnatl_reg_GRP_oecd.tex", replace f  ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
label booktabs nomtitle nobaselevels collabels(none) ///
scalars("NC Number of Groups" "WR2 Adjusted Within R-squared" "AGG Aggregation Level") ///
sfmt(3)

