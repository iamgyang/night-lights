
/* List out the files we want to create manual FE for: */
est clear
	clear	
		input str40 files_to_FE
		"sample_iso3c_year_pop_den__allvars2"
        "India_Indonesia_Brazil_subnational"
		end
	levelsof files_to_FE, local(files_to_FE)

/* Create manual fixed effects */

foreach file in `files_to_FE' {
    use "$input/`file'.dta", clear
	keep if year >= 2012
    if ("`file'" == "sample_iso3c_year_pop_den__allvars2") {
		local est_name global
        local location iso3c
        local Y WDI_ppp
        local AGG "Country"
        local Region_FE ""
        local Country_FE "X"
        local extra_NTL_var del_sum_pix_94
    }
    /* else if ("`file'" == "adm1_oecd_ntl_grp") {
        local est_name oecd
        local location region
        local Y GRP
        local AGG "Admin 1"
        local Region_FE "X"
        local Country_FE ""
    } */
    else if ("`file'" == "India_Indonesia_Brazil_subnational") {
        drop if iso3c == "USA"
		local est_name iib
        local location region
        local Y GRP
        local AGG "Admin 1"
        local Region_FE "X"
        local Country_FE ""
    }

    keep ln_`Y' `location' year ln_del_sum_pix_area `extra_NTL_var' del_sum_pix iso3c
    naomit
    create_categ(`location')

    gen covid_dummy = 1 if year == 2020
    replace covid_dummy = 0 if year != 2020
    assert !mi(covid_dummy)
	label variable covid_dummy "Covid Dummy"

    if ("`file'" == "sample_iso3c_year_pop_den__allvars2") {
        gen ln_del_sum_pix_94 = log(del_sum_pix_94)
        reghdfe ln_del_sum_pix_94 covid_dummy, absorb(cat_`location') vce(cluster cat_`location')
        eststo `est_name'reg2
        estadd local AGG "`AGG'"
        estadd local NC `e(N_clust)'
        local y = round(`e(r2_a_within)', .001)
        estadd local WR2 `y'
        estadd local Region_FE "`Region_FE'"
        estadd local Country_FE "`Country_FE'"
    }

    gen ln_del_sum_pix = log(del_sum_pix)
    reghdfe ln_del_sum_pix covid_dummy, absorb(cat_`location') vce(cluster cat_`location')
    eststo `est_name'reg1
    estadd local AGG "`AGG'"
    estadd local NC `e(N_clust)'
    local y = round(`e(r2_a_within)', .001)
    estadd local WR2 `y'
    estadd local Region_FE "`Region_FE'"
    estadd local Country_FE "`Country_FE'"

    
}

esttab iibreg1 globalreg1 globalreg2  ///
using "$overleaf/covid_levels.tex", ///
mgroups("India, Indonesia, Brazil" "Global" "Global (94th pct pop density)", pattern(1 1 1) span prefix(\multicolumn{@span}{c}{) suffix(})) ///
scalars("AGG Aggregation Level" "NC Number of Groups" "WR2 Adjusted Within R-squared" "Region_FE Region Fixed Effects" "Country_FE Country Fixed Effects") ///
nomtitles ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) sfmt(3) ///
label booktabs nobaselevels  drop(_cons) ///
replace f









