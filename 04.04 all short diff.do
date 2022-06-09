/* Do all annual difference regressions */

est clear

/* SUBNATIONAL LEVEL ----------- */

/* India, Indonesia, Brazil */
use "$input/India_Indonesia_Brazil_subnational.dta", clear
create_categ(iso3c)
fillin ADM1 year
sort ADM1 year
foreach var of varlist ln_* {
	sort ADM1 year
    by ADM1: generate g_`var' = `var' - `var'[_n-1] if ADM1==ADM1[_n-1]
	loc lab: variable label `var'
	label variable g_`var' "Diff. `lab'"
}
drop if mi(g_ln_del_sum_pix_area) | mi(g_ln_GRP)
drop if iso3c == "USA"
reghdfe g_ln_GRP g_ln_del_sum_pix_area, absorb(cat_ADM1 cat_year)
eststo subn1
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'
estadd local AGG "Admin 1"
estadd local ADM1_FE "X"
estadd local Year_FE "X"
estadd local Country_FE ""

reghdfe g_ln_GRP g_ln_del_sum_pix_area, absorb(cat_iso3c cat_year)
eststo subn3
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Admin 1"
estadd local ADM1_FE ""
estadd local Year_FE "X"
estadd local Country_FE "X"

/* OECD */
use "$input/adm1_oecd_ntl_grp.dta", clear
fillin ADM1 year
sort ADM1 year
foreach var of varlist ln_* {
	sort ADM1 year
    by ADM1: generate g_`var' = `var' - `var'[_n-1] if ADM1==ADM1[_n-1]
	loc lab: variable label `var'
	label variable g_`var' "Diff. `lab'"
}
drop if mi(g_ln_del_sum_pix_area) | mi(g_ln_GRP)
reghdfe g_ln_GRP g_ln_del_sum_pix_area, absorb(cat_ADM1 cat_year)
eststo subn2
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Admin 1"
estadd local ADM1_FE "X"
estadd local Year_FE "X"
estadd local Country_FE ""

reghdfe g_ln_GRP g_ln_del_sum_pix_area, absorb(cat_iso3c cat_year)
eststo subn4
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Admin 1"
estadd local ADM1_FE ""
estadd local Year_FE "X"
estadd local Country_FE "X"

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
sort iso3c year
foreach var of varlist ln_* {
	sort iso3c year
    by iso3c: generate g_`var' = `var' - `var'[_n-1] if iso3c==iso3c[_n-1]
	loc lab: variable label `var'
	label variable g_`var' "Diff. `lab'"
}
drop if mi(g_ln_del_sum_pix_area) | mi(g_ln_GRP)
reghdfe g_ln_GRP g_ln_del_sum_pix_area, absorb(cat_iso3c cat_year)
eststo country1
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Country"
estadd local ADM1_FE ""
estadd local Year_FE "X"
estadd local Country_FE "X"

/* OECD */
use "$input/adm1_oecd_ntl_grp.dta", clear
gcollapse (sum) GRP del_sum_pix del_sum_area, by(iso3c year)
create_categ(iso3c year)
gen ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
gen ln_GRP = ln(GRP)
label variable ln_del_sum_pix_area "Log(VIIRS pixels/area)"
label variable ln_GRP "Log(Gross Regional Product)"
fillin iso3c year
sort iso3c year
foreach var of varlist ln_* {
	sort iso3c year
    by iso3c: generate g_`var' = `var' - `var'[_n-1] if iso3c==iso3c[_n-1]
	loc lab: variable label `var'
	label variable g_`var' "Diff. `lab'"
}
drop if mi(g_ln_del_sum_pix_area) | mi(g_ln_GRP)
reghdfe g_ln_GRP g_ln_del_sum_pix_area, absorb(cat_iso3c cat_year)
eststo country2
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Country"
estadd local ADM1_FE ""
estadd local Year_FE "X"
estadd local Country_FE "X"

/* COUNTRY LEVEL USING WDI LCU ----------- */

/* Global */
use "$input/iso3c_year_aggregation.dta", clear
reghdfe g_ln_WDI g_ln_del_sum_pix_area, absorb(cat_iso3c cat_year)
eststo country_wdi3
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Country"
estadd local ADM1_FE ""
estadd local Year_FE "X"
estadd local Country_FE "X"

/* India, Indonesia, Brazil */
use "$input/iso3c_year_aggregation.dta", clear
keep if iso3c == "IND" | iso3c == "BRA" | iso3c == "IDN"
reghdfe g_ln_WDI g_ln_del_sum_pix_area, absorb(cat_iso3c cat_year)
eststo country_wdi1
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Country"
estadd local ADM1_FE ""
estadd local Year_FE "X"
estadd local Country_FE "X"

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
reghdfe g_ln_WDI g_ln_del_sum_pix_area, absorb(cat_iso3c cat_year)
eststo country_wdi2
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Country"
estadd local ADM1_FE ""
estadd local Year_FE "X"
estadd local Country_FE "X"

/* EXPORT ----------- */

esttab country_wdi1 country_wdi2 country_wdi3 using "$overleaf/all_annual_growth.tex", ///
posthead("\hline \\ \multicolumn{4}{l}{\textbf{Panel A: Country level, using GDP from WDI, LCU}} \\\\[-1ex]") ///
fragment ///
mgroups("India, Indonesia, Brazil" "OECD" "Global", pattern(1 1 1) span prefix(\multicolumn{@span}{c}{) suffix(})) ///
scalars("AGG Aggregation Level" "NC Number of Groups" "WR2 Adjusted Within R-squared" "ADM1_FE Admin. 1 Fixed Effects" "Country_FE Country Fixed Effects" "Year_FE Year Fixed Effects" ) ///
nomtitles ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01 **** 0.001) sfmt(3) ///
label booktabs nobaselevels  drop(_cons) ///
replace

esttab subn1 subn2 using "$overleaf/all_annual_growth.tex", ///
posthead("\hline \\ \multicolumn{4}{l}{\textbf{Panel B: Subnational level, using GRP (ADM1 FE)}} \\\\[-1ex]") ///
fragment ///
append ///
scalars("AGG Aggregation Level" "NC Number of Groups" "WR2 Adjusted Within R-squared" "ADM1_FE Admin. 1 Fixed Effects" "Country_FE Country Fixed Effects" "Year_FE Year Fixed Effects") ///
nomtitles nonumbers nolines ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01 **** 0.001) sfmt(3) ///
label booktabs nobaselevels drop(_cons)

esttab subn3 subn4 using "$overleaf/all_annual_growth.tex", ///
posthead("\hline \\ \multicolumn{4}{l}{\textbf{Panel C: Subnational level, using GRP (Country FE)}} \\\\[-1ex]") ///
fragment ///
append ///
scalars("AGG Aggregation Level" "NC Number of Groups" "WR2 Adjusted Within R-squared" "ADM1_FE Admin. 1 Fixed Effects" "Country_FE Country Fixed Effects" "Year_FE Year Fixed Effects") ///
nomtitles nonumbers nolines ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01 **** 0.001) sfmt(3) ///
label booktabs nobaselevels drop(_cons)

esttab country1 country2 using "$overleaf/all_annual_growth.tex", ///
posthead("\hline \\ \multicolumn{4}{l}{\textbf{Panel D: Country level, using GDP as  summed subnational GRP}} \\\\[-1ex]") ///
fragment ///
append ///
scalars( "AGG Aggregation Level" "NC Number of Groups" "WR2 Adjusted Within R-squared" "ADM1_FE Admin. 1 Fixed Effects" "Country_FE Country Fixed Effects" "Year_FE Year Fixed Effects") ///
nomtitles nonumbers nolines ///
prefoot("\hline") ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01 **** 0.001) sfmt(3) ///
label booktabs nobaselevels drop(_cons)


