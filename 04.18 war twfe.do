use "$input/war_adm2_month.dta", clear
replace deaths = deaths/1000
reghdfe ln_sum_pix_bm_area deaths, absorb(cat_objectid cat_year cat_month)
eststo reg1
estadd local NC `e(N_clust)'
local y = round(`e(r2_a_within)', .001)
estadd local WR2 `y'
estadd local AGG "Admin. 2"
estadd local ADM1_FE ""
estadd local ADM2_FE "X"
estadd local Year_FE "X"
estadd local Month_FE "X"
estadd local Country_FE ""

esttab reg1 using "$overleaf/war_twfe.tex", replace f  ///
scalars("WR2 Adjusted Within R-squared" "Country_FE Country Fixed Effects" "ADM1_FE Admin. 1 Fixed Effects" "ADM2_FE Admin. 2 Fixed Effects" "Year_FE Year Fixed Effects") ///
b(3) se(3) ar2 nomtitle label star(* 0.10 ** 0.05 *** 0.01 **** 0.001) ///
booktabs collabels(none) coeflabel(deaths "Deaths (1K)")
.