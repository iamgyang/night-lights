// This produces a regression on how much COVID-19 ended up depressing night
// lights in 2020 at an annual country level.

est clear
clear

foreach light_label in VIIRS BM {
foreach income_group in OECD Not_OECD Global {
foreach file in iso3c_year_aggregation adm1_year_aggregation {
    use "$input/`file'.dta", clear
	if ("`income_group'" == "OECD") {
		keep_oecd iso3c
	} 
	if ("`income_group'" == "Not_OECD") {
		drop_oecd iso3c
	}

    if ("`light_label'" == "VIIRS") {
        local light_var ln_del_sum_pix
    }
    if ("`light_label'" == "BM") {
        local light_var ln_sum_pix_bm
    }

	keep if year >= 2012
    if ("`file'" == "iso3c_year_aggregation") {
        local location iso3c
        local AGG "Country"
        local ADM1_FE ""
        local Country_FE "X"
    }
    else if ("`file'" == "adm1_year_aggregation") {
        local location ADM1
        local AGG "Admin1"
        local ADM1_FE "X"
        local Country_FE ""
    }
    
    keep `location' year `light_var' `extra_NTL_var' iso3c
    naomit
    create_categ(`location')
    
    // indicator variable for COVID-19
        gen covid_dummy = 1 if year >= 2020
        replace covid_dummy = 0 if !(year >= 2020)
        assert !mi(covid_dummy)
        label variable covid_dummy "Covid Dummy"

        reghdfe `light_var' covid_dummy, absorb(cat_`location') vce(cluster cat_`location')
        eststo reg_`income_group'_`light_label'_`location'
        estadd local AGG "`AGG'"
        estadd local NC `e(N_clust)'
        local y = round(`e(r2_a_within)', .001)
        estadd local WR2 `y'
        estadd local ADM1_FE "`ADM1_FE'"
        estadd local Country_FE "`Country_FE'"
}
}
}

/* EXPORT ----------- */

esttab reg_Global_VIIRS_iso3c reg_Global_BM_iso3c reg_OECD_VIIRS_iso3c ///
reg_OECD_BM_iso3c reg_Not_OECD_VIIRS_iso3c reg_Not_OECD_BM_iso3c using "$overleaf/covid_levels.tex", ///
posthead("\hline \\ \multicolumn{4}{l}{\textbf{Panel A: Country level}} \\\\[-1ex]") ///
fragment ///
mgroups("Global VIIRS" "Global BM" "OECD VIIRS" "OECD BM" "Not OECD VIIRS" "Not OECD BM", pattern(1 1 1 1 1 1 1 1 1 1 1 1) span prefix(\multicolumn{@span}{c}{) suffix(})) ///
scalars("AGG Aggregation Level" "NC Number of Groups" "WR2 Adjusted Within R-squared" "ADM1_FE ADM1 Fixed Effects" "Country_FE Country Fixed Effects") ///
nomtitles ///
b(3) se(3) ar2 star(* 0.10 ** 0.05 *** 0.01) sfmt(3) ///
label booktabs nobaselevels  drop(_cons) ///
replace

esttab reg_Global_VIIRS_ADM1 reg_Global_BM_ADM1 reg_OECD_VIIRS_ADM1 ///
reg_OECD_BM_ADM1 reg_Not_OECD_VIIRS_ADM1 reg_Not_OECD_BM_ADM1 using "$overleaf/covid_levels.tex", ///
posthead("\hline \\ \multicolumn{4}{l}{\textbf{Panel B: ADM1 level}} \\\\[-1ex]") ///
fragment ///
append ///
scalars("AGG Aggregation Level" "NC Number of Groups" "WR2 Adjusted Within R-squared" "ADM1_FE ADM1 Fixed Effects" "Country_FE Country Fixed Effects") ///
nomtitles nonumbers nolines ///
b(3) se(3) ar2 star(* 0.10 ** 0.05 *** 0.01) sfmt(3) ///
label booktabs nobaselevels drop(_cons)






















