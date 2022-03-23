/* Do all log levels regressions */

est clear
use "C:/Users/gyang/Dropbox/CGD GlobalSat/raw-data/Black Marble NTL/bm_adm1_1622.dta"

/* SUBNATIONAL LEVEL ----------- */

/* India, Indonesia, Brazil */
use "$input/India_Indonesia_Brazil_subnational.dta", clear
create_categ(iso3c)
drop if iso3c == "USA"
reghdfe ln_GRP ln_del_sum_pix_area, absorb(cat_region cat_year) vce(cluster cat_region)
eststo subn1
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Admin 1"
estadd local Region_FE "X"
estadd local Year_FE "X"
estadd local Country_FE ""

reghdfe ln_GRP ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
eststo subn3
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Admin 1"
estadd local Region_FE ""
estadd local Year_FE "X"
estadd local Country_FE "X"

/* OECD */
use "$input/adm1_oecd_ntl_grp.dta", clear
reghdfe ln_GRP ln_del_sum_pix_area, absorb(cat_region cat_year) vce(cluster cat_region)
eststo subn2
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Admin 1"
estadd local Region_FE "X"
estadd local Year_FE "X"
estadd local Country_FE ""

reghdfe ln_GRP ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
eststo subn4
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Admin 1"
estadd local Region_FE ""
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
reghdfe ln_GRP ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
eststo country1
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Country"
estadd local Region_FE ""
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
reghdfe ln_GRP ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
eststo country2
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Country"
estadd local Region_FE ""
estadd local Year_FE "X"
estadd local Country_FE "X"

/* COUNTRY LEVEL USING WDI LCU ----------- */

/* Global */
use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear
reghdfe ln_WDI ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
eststo country_wdi3
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Country"
estadd local Region_FE ""
estadd local Year_FE "X"
estadd local Country_FE "X"

/* India, Indonesia, Brazil */
use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear
keep if iso3c == "IND" | iso3c == "BRA" | iso3c == "IDN"
reghdfe ln_WDI ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
eststo country_wdi1
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'	
estadd local AGG "Country"
estadd local Region_FE ""
estadd local Year_FE "X"
estadd local Country_FE "X"

/* OECD */

/* get the OECD countries we have from the ADM1 dataset */
use "$input/adm1_oecd_ntl_grp.dta", clear
levelsof iso3c, local(country_codes)

use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear
gen tokeep = "No"
foreach i in `country_codes' {
    replace tokeep = "Yes" if iso3c == "`i'"
}
keep if tokeep == "Yes"
drop tokeep
reghdfe ln_WDI ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
eststo country_wdi2
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'
estadd local AGG "Country"
estadd local Region_FE ""
estadd local Year_FE "X"
estadd local Country_FE "X"

/* EXPORT ----------- */

esttab country_wdi1 country_wdi2 country_wdi3 using "$overleaf/all_log_levels.tex", ///
posthead("\hline \\ \multicolumn{4}{l}{\textbf{Panel A: Country level, using GDP from WDI, LCU}} \\\\[-1ex]") ///
fragment ///
mgroups("India, Indonesia, Brazil" "OECD" "Global", pattern(1 1 1) span prefix(\multicolumn{@span}{c}{) suffix(})) ///
scalars("AGG Aggregation Level" "NC Number of Groups" "WR2 Adjusted Within R-squared" "Region_FE Region Fixed Effects" "Country_FE Country Fixed Effects" "Year_FE Year Fixed Effects" ) ///
nomtitles ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) sfmt(3) ///
label booktabs nobaselevels  drop(_cons) ///
replace

esttab subn1 subn2 using "$overleaf/all_log_levels.tex", ///
posthead("\hline \\ \multicolumn{4}{l}{\textbf{Panel B: Subnational level, using GRP (Region FE)}} \\\\[-1ex]") ///
fragment ///
append ///
scalars("AGG Aggregation Level" "NC Number of Groups" "WR2 Adjusted Within R-squared" "Region_FE Region Fixed Effects" "Country_FE Country Fixed Effects" "Year_FE Year Fixed Effects") ///
nomtitles nonumbers nolines ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) sfmt(3) ///
label booktabs nobaselevels drop(_cons)

esttab subn3 subn4 using "$overleaf/all_log_levels.tex", ///
posthead("\hline \\ \multicolumn{4}{l}{\textbf{Panel C: Subnational level, using GRP (Country FE)}} \\\\[-1ex]") ///
fragment ///
append ///
scalars("AGG Aggregation Level" "NC Number of Groups" "WR2 Adjusted Within R-squared" "Region_FE Region Fixed Effects" "Country_FE Country Fixed Effects" "Year_FE Year Fixed Effects") ///
nomtitles nonumbers nolines ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) sfmt(3) ///
label booktabs nobaselevels drop(_cons)

esttab country1 country2 using "$overleaf/all_log_levels.tex", ///
posthead("\hline \\ \multicolumn{4}{l}{\textbf{Panel D: Country level, using GDP as  summed subnational GRP}} \\\\[-1ex]") ///
fragment ///
append ///
scalars( "AGG Aggregation Level" "NC Number of Groups" "WR2 Adjusted Within R-squared" "Region_FE Region Fixed Effects" "Country_FE Country Fixed Effects" "Year_FE Year Fixed Effects") ///
nomtitles nonumbers nolines ///
prefoot("\hline") ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) sfmt(3) ///
label booktabs nobaselevels drop(_cons)

/////////////////////////////////////////////






























