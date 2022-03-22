// Subnational GRP regressions (EU): ---------------------------------------

// get WB statistical quality indicators:
use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear
keep wbdqcat_3 iso3c
gduplicates drop
naomit
tempfile wb_stat_capacity
save `wb_stat_capacity'

// get Europe regional GDP variable and generate categorical variables and log variables
use "$input/NUTS_validation.dta", clear
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
create_categ reg_name
// run regressions
gr_lev_reg, levels outfile("$overleaf/NUTS_regression.tex") ///
	dep_vars(ln_del_sum_pix_area) ///
	abs_vars(cat_reg_name cat_year) ///
	cluster_vars(cat_reg_name) ///
	dep_var_label("Log VIIRS (cleaned) pixels/area")
	
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
save "$input/India_Indonesia_Brazil_subnational.dta", replace

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

// Subnational GRP regressions (all OECD CITY LEVEL) ------------------------------------------------------

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

// Subnational GRP regressions (all OECD ADM1 LEVEL) ----------------------------------

// import subnational map data
use "$raw_data/National Accounts/geo_coded_data/oecd2_adm2NTL_map17feb22.dta", clear
keep NAME_0 NAME_1 iso3c regional_name
rename *, lower
decode_vars, all
gduplicates drop
naomit
tempfile map
save `map'

// import subnational GRP
mmerge iso3c regional_name using "$input/oecd_tl2.dta"
keep if _merge ==3 // !!!!!!! some were not geocoded accurately
assert _merge == 3
drop _merge
rename value GRP
rename regional_name region
rename iso3c iso3c_grp
tempfile grp_subnatl
save `grp_subnatl'

// clean night lights (only VIIRS cleaned version)
use "$input/NTL_VIIRS_appended_cleaned_all.dta", clear
rename *, lower
keep objectid iso3c year month del_sum_pix del_sum_area sum_pix sum_area name_0 name_1
gcollapse (sum) del_sum_pix sum_pix (mean) del_sum_area sum_area, by(objectid iso3c name_0 name_1 year)
gcollapse (sum) del_sum_pix sum_pix del_sum_area sum_area, by(iso3c name_0 name_1 year)
rename iso3c iso3c_ntl

// merge with night lights
mmerge name_0 name_1 year using `grp_subnatl'
keep if _merge == 3
drop _merge
drop if iso3c_ntl != iso3c_grp 
assert iso3c_ntl == iso3c_grp // !!!!!!! some were not geocoded accurately
rename iso3c_grp iso3c
check_dup_id "region iso3c year"
// check_dup_id "name_0 name_1 iso3c year"
bys name_0 name_1 year: gen n = _N
// br if n>1 !!!!!! some were not geocoded accurately again!
keep if n==1

// collapse to OECD region level
gcollapse (sum) del_sum_pix sum_pix del_sum_area sum_area (mean) GRP, by(region iso3c year)

// create variables of interest
gen ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
gen ln_sum_pix_area = ln(sum_pix/sum_area)
create_logvars "GRP del_sum_pix sum_pix"
label variable ln_del_sum_pix_area "Log(VIIRS pixels/area)"
label variable ln_sum_pix_area "Log(VIIRS pixels/area)"
label variable ln_GRP "Log(Gross Regional Product)"

// save:
save "$input/oecd_prior_to_reg.dta", replace

// graph:
sepscatter ln_del_sum_pix_area ln_GRP, mc(red blue green purple) separate(iso3c) legend(size(*0.5) symxsize(*5) position(0) bplacement(nwest) region(lwidth(none)))
gr export "$overleaf/scatter_GRP_log_log_subnatl_oecd.pdf", replace

// regressions
create_categ(region iso3c year)

save "$input/adm1_oecd_ntl_grp.dta", replace
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

// Subnational GRP regressions (India) ----------------------------------

// GRP data
use "$raw_data/National Accounts/geo_coded_data/global_subnational_ntlmerged_woPHL.dta", clear
keep if iso3c_x == "IND"
keep year region GRP iso3c_x gid_1 name_1
rename iso3c_x iso3c
check_dup_id "gid_1 year iso3c"
tempfile grp_subnatl_IND
save `grp_subnatl_IND'

// VIIRS NTL
use "$input/NTL_VIIRS_appended_cleaned_all.dta", clear
keep if iso3c == "IND"
keep objectid iso3c gid_1 year month del_sum_pix del_sum_area
gcollapse (sum) del_sum_pix (mean) del_sum_area, by(objectid iso3c gid_1 year)
gcollapse (sum) del_sum_pix del_sum_area, by(iso3c gid_1 year)
label variable del_sum_pix "VIIRS (cleaned) sum of pixels"
label variable del_sum_area "VIIRS (cleaned) polygon area" 
check_dup_id "iso3c gid_1 year"
tempfile VIIRS_ntl
save `VIIRS_ntl'

// BM NTL
use "$raw_data/Black Marble NTL/India/black_marble_india.dta", clear
decode_vars, all
keep objectid year month r_sum pol_area s_nm name_0 gid_1 name_1 gid_2
naomit
gcollapse (sum) r_sum (mean) pol_area, by(objectid gid_1 year)
gcollapse (sum) r_sum pol_area, by(gid_1 year)
check_dup_id "gid_1 year"
destring year, replace
label variable r_sum "BM sum of pixels"
label variable pol_area "BM polygon area" 
rename r_sum r_sum_pix
tempfile BM_ntl
save `BM_ntl'

// merge all
clear
use `grp_subnatl_IND'
mmerge gid_1 year using `VIIRS_ntl'
mmerge gid_1 year using `BM_ntl'

// create variables of interest (first differences)
gen del_sum_pix_area = del_sum_pix/del_sum_area
gen r_sum_pix_area = r_sum_pix/pol_area
label variable r_sum_pix_area "BM pixels/area"
label variable del_sum_pix_area "VIIRS pixels/area"
label variable GRP "Gross Regional Product"

drop region
rename gid_1 region
create_categ(region year)

foreach var in GRP r_sum_pix_area r_sum_pix del_sum_pix del_sum_pix_area {
	sort region year
	by region: gen ln_diff_`var' = log(`var'/`var'[_n-1]) if region == region[_n-1]
	loc lab: variable label `var'
	label variable ln_diff_`var' "Log Diff. `lab'"
}
create_logvars "r_sum_pix del_sum_pix del_sum_pix_area r_sum_pix_area GRP"

// checks
scatter pol_area del_sum_area
scatter del_sum_pix r_sum_pix

levelsof region, local(region_levels)
// foreach region in `region_levels' {
// 	scatter ln_GRP ln_r_sum_pix if region == "`region'"
// 	graph export "$input/`region'_india_lights_assoc.pdf"
// }
scatter ln_GRP ln_r_sum_pix 
scatter ln_diff_GRP ln_diff_r_sum_pix

// save
save "$input/data_prior_to_india_regressions.dta", replace

// clear regression estimates
est clear

// regressions
// log GDP ~ log lights
eststo: reghdfe ln_diff_GRP ln_diff_del_sum_pix, absorb(cat_region cat_year) vce(cluster cat_region)
estadd local NC `e(N_clust)'
local y= round(`e(r2_a_within)', .001)
estadd local WR2 `y'
estadd local AGG "ADM1"

eststo: reghdfe ln_GRP ln_del_sum_pix_area, absorb(cat_region cat_year) vce(cluster cat_region)
estadd local NC `e(N_clust)'
local y= round(`e(r2_a_within)', .001)
estadd local WR2 `y'
estadd local AGG "ADM1"

eststo: reghdfe ln_GRP ln_r_sum_pix, absorb(cat_region cat_year) vce(cluster cat_region)
estadd local NC `e(N_clust)'
local y= round(`e(r2_a_within)', .001)
estadd local WR2 `y'
estadd local AGG "ADM1"

// export results into a tex file
esttab using "$overleaf/subnatl_reg_GRP_IND.tex", replace f  ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
label booktabs nomtitle nobaselevels collabels(none) ///
scalars("NC Number of Groups" "WR2 Adjusted Within R-squared" "AGG Aggregation Level") ///
sfmt(3)

