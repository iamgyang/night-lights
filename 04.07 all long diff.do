/* Do all long difference regressions (i.e. difference across multiple years) */

est clear

/* SUBNATIONAL LEVEL ----------- */

/* India, Indonesia, Brazil */
use "$input/India_Indonesia_Brazil_subnational.dta", clear
create_categ(iso3c)
fillin ADM1 year
keep if year == 2013 | year == 2019
sort ADM1 year
foreach var of varlist ln_* {
	bys ADM1: gen lg_`var' =  `var' - `var'[_n-1] if ADM1==ADM1[_n-1]
	loc lab: variable label `var'
	label variable lg_`var' "Long Difference `lab'"
}
drop if mi(lg_ln_del_sum_pix_area) | mi(lg_ln_GRP)
drop if iso3c == "USA"
check_dup_id "ADM1"
reg lg_ln_GRP lg_ln_del_sum_pix_area, vce(hc3)
eststo subn1
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local AGG "Admin 1"

/* OECD */
use "$input/adm1_oecd_ntl_grp.dta", clear
fillin ADM1 year
keep if year == 2013 | year == 2019
sort ADM1 year
foreach var of varlist ln_* {
	sort ADM1 year
    by ADM1: generate lg_`var' = `var' - `var'[_n-1] if ADM1==ADM1[_n-1]
	loc lab: variable label `var'
	label variable lg_`var' "Long Difference `lab'"
}
drop if mi(lg_ln_del_sum_pix_area) | mi(lg_ln_GRP)
check_dup_id "ADM1"
reg lg_ln_GRP lg_ln_del_sum_pix_area, vce(hc3)
eststo subn2
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local AGG "Admin 1"

/* COUNTRY LEVEL USING AGGREGATED SUBNATIONAL GDP ----------- */

/* India, Indonesia, Brazil */
use "$input/India_Indonesia_Brazil_subnational.dta", clear
drop if iso3c == "USA"
gcollapse (sum) GRP del_sum_pix del_sum_area, by(iso3c year)
create_categ(iso3c year)
gen ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
gen ln_GRP = ln(GRP)
label variable ln_del_sum_pix_area "Log(VIIRS pixels/area)"
label variable ln_GRP "Log(Gross Regional Product)"
fillin iso3c year
keep if year == 2013 | year == 2019
sort iso3c year
foreach var of varlist ln_* {
	sort iso3c year
    by iso3c: generate lg_`var' = `var' - `var'[_n-1] if iso3c==iso3c[_n-1]
	loc lab: variable label `var'
	label variable lg_`var' "Long Difference `lab'"
}
drop if mi(lg_ln_del_sum_pix_area) | mi(lg_ln_GRP)
check_dup_id "iso3c"
reg lg_ln_GRP lg_ln_del_sum_pix_area, vce(hc3)
eststo country1
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local AGG "Country"

/* OECD */
use "$input/adm1_oecd_ntl_grp.dta", clear
gcollapse (sum) GRP del_sum_pix del_sum_area, by(iso3c year)
create_categ(iso3c year)
gen ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
gen ln_GRP = ln(GRP)
label variable ln_del_sum_pix_area "Log(VIIRS pixels/area)"
label variable ln_GRP "Log(Gross Regional Product)"
fillin iso3c year
keep if year == 2013 | year == 2019
sort iso3c year
foreach var of varlist ln_* {
	sort iso3c year
    by iso3c: generate lg_`var' = `var' - `var'[_n-1] if iso3c==iso3c[_n-1]
	loc lab: variable label `var'
	label variable lg_`var' "Long Difference `lab'"
}
drop if mi(lg_ln_del_sum_pix_area) | mi(lg_ln_GRP)
check_dup_id "iso3c"
reg lg_ln_GRP lg_ln_del_sum_pix_area, vce(hc3)
eststo country2
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local AGG "Country"

/* COUNTRY LEVEL USING WDI LCU ----------- */

/* Global */
use "$input/iso3c_year_aggregation.dta", clear
fillin iso3c year
keep if year == 2013 | year == 2019
sort iso3c year
foreach var of varlist ln_* {
	sort iso3c year
    by iso3c: generate lg_`var' = `var' - `var'[_n-1] if iso3c==iso3c[_n-1]
	loc lab: variable label `var'
	label variable lg_`var' "Long Difference `lab'"
}
drop if mi(lg_ln_WDI) | mi(lg_ln_del_sum_pix_area)
check_dup_id "iso3c"
reg lg_ln_WDI lg_ln_del_sum_pix_area, vce(hc3)
eststo country_wdi3
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local AGG "Country"


/* India, Indonesia, Brazil */
use "$input/iso3c_year_aggregation.dta", clear
keep if iso3c == "IND" | iso3c == "BRA" | iso3c == "IDN"
fillin iso3c year
keep if year == 2013 | year == 2019
sort iso3c year
foreach var of varlist ln_* {
	sort iso3c year
    by iso3c: generate lg_`var' = `var' - `var'[_n-1] if iso3c==iso3c[_n-1]
	loc lab: variable label `var'
	label variable lg_`var' "Long Difference `lab'"
}
drop if mi(lg_ln_WDI) | mi(lg_ln_del_sum_pix_area)
check_dup_id "iso3c"
reg lg_ln_WDI lg_ln_del_sum_pix_area, vce(hc3)
eststo country_wdi1
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local AGG "Country"


/* OECD */

/* get the OECD countries we have from the ADM1 dataset */
use "$input/adm1_oecd_ntl_grp.dta", clear
levelsof iso3c, local(country_codes)

use "$input/iso3c_year_aggregation.dta", clear
gen tokeep = "No"
foreach i in `country_codes' {
    replace tokeep = "Yes" if iso3c == "`i'"
}
keep if tokeep == "Yes"
drop tokeep
fillin iso3c year
keep if year == 2013 | year == 2019
sort iso3c year
foreach var of varlist ln_* {
	sort iso3c year
    by iso3c: generate lg_`var' = `var' - `var'[_n-1] if iso3c==iso3c[_n-1]
	loc lab: variable label `var'
	label variable lg_`var' "Long Difference `lab'"
}
drop if mi(lg_ln_WDI) | mi(lg_ln_del_sum_pix_area)
check_dup_id "iso3c"
reg lg_ln_WDI lg_ln_del_sum_pix_area, vce(hc3)
eststo country_wdi2
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local AGG "Country"

/* EXPORT ----------- */

esttab country_wdi1 country_wdi2 country_wdi3 using "$overleaf/all_long_diff.tex", ///
posthead("\hline \\ \multicolumn{4}{l}{\textbf{Panel A: Country level, using GDP from WDI, LCU}} \\\\[-1ex]") ///
fragment ///
mgroups("India, Indonesia, Brazil" "OECD" "Global", pattern(1 1 1) span prefix(\multicolumn{@span}{c}{) suffix(})) ///
scalars("AGG Aggregation Level" ) ///
nomtitles ///
b(3) se(3) ar2 star(* 0.10 ** 0.05 *** 0.01) sfmt(3) ///
label booktabs nobaselevels  drop(_cons) ///
replace

esttab subn1 subn2 using "$overleaf/all_long_diff.tex", ///
posthead("\hline \\ \multicolumn{4}{l}{\textbf{Panel B: Subnational level, using GRP}} \\\\[-1ex]") ///
fragment ///
append ///
scalars("AGG Aggregation Level" ) ///
nomtitles nonumbers nolines ///
b(3) se(3) ar2 star(* 0.10 ** 0.05 *** 0.01) sfmt(3) ///
label booktabs nobaselevels drop(_cons)

