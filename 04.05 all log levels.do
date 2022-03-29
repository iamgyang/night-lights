/* Do all log levels regressions */
pause off // CHANGE!!!!

est clear
clear	

// macro stores which nonOECD countries are present in the subnational GRP data
capture macro drop isos_in_subnat

foreach file in subnational_GRP sample_iso3c_year_pop_den__allvars2 {
	foreach light_label in VIIRS BM {
		foreach income_group in OECD n_O Glo {
			use "$input/`file'.dta", clear
			keep if year >= 2012

			// restrict the countries to those of interest
			if ("`income_group'" == "OECD") {
				keep_oecd iso3c
			} 
			if ("`income_group'" == "n_O") {
				drop_oecd iso3c
			}
			if ("`income_group'" == "n_O" & "`file'" == "sample_iso3c_year_pop_den__allvars2") {
				gen to_keep = "no"
				foreach i in `isos_in_subnat' {
					replace to_keep = "yes" if iso3c == "`i'"
				}
				replace to_keep = "" if mi(iso3c)
				pause checking whether the to_keep variable is labeled correctly
				keep if to_keep == "yes"
				drop to_keep        
			}

			// define local macros that will help us label & run the regression

			if ("`light_label'" == "VIIRS") {
				local light_var del_sum_pix
				local loc_var del_sum_area
			}
			if ("`light_label'" == "BM") {
				local light_var sum_pix_bm
				local loc_var pol_area
			}
			label variable ln_`light_var'_area "Log(`light_label' pixels/area)"
			pause u9090uu90r0

			if ("`file'" == "sample_iso3c_year_pop_den__allvars2") {
				local location iso3c
				local Y WDI
				local AGG "Country"
				local Region_FE ""
				local Country_FE "X"
				label variable ln_`Y' "Log(GDP, LCU)"
			}
			else if ("`file'" == "subnational_GRP") {
				local location region
				local Y GRP
				local AGG "Admin1"
				local Region_FE "X"
				local Country_FE ""
				label variable ln_`Y' "Log(GRP)"
			}

			// indicator variable for COVID-19
			gen covid_dummy = 1 if year >= 2020
			replace covid_dummy = 0 if !(year >= 2020)
			assert !mi(covid_dummy)
			label variable covid_dummy "Covid Dummy"
			
			preserve
				keep ln_`Y' `location' year ln_`light_var'_area iso3c covid_dummy
				naomit
				create_categ(`location' year)

				// get which countries were used for the subnational bit:
				if ("`file'" == "subnational_GRP" & "`income_group'" == "n_O") {
					levelsof iso3c, local(isos_in_subnat)
				}


				// regression
				pause `file' `light_label' `income_group' FIRST REGRESSION
				reghdfe ln_`Y' ln_`light_var'_area c.ln_`light_var'_area#covid_dummy, absorb(cat_`location' cat_year) vce(cluster cat_`location')
				eststo reg_`income_group'_`light_label'_`location'_`Y'_c
				di "reg_`income_group'_`light_label'_`location'_`Y'_c"
				estadd local AGG "`AGG'"
				estadd local NC `e(N_clust)'
				local y = round(`e(r2_a_within)', .001)
				estadd local WR2 `y'
				estadd local Region_FE "`Region_FE'"
				estadd local Country_FE "`Country_FE'"
				estadd local Year_FE "X"

				pause `file' `light_label' `income_group' SECOND REGRESSION
				reghdfe ln_`Y' ln_`light_var'_area, absorb(cat_`location' cat_year) vce(cluster cat_`location')
				eststo reg_`income_group'_`light_label'_`location'_`Y'
				di "reg_`income_group'_`light_label'_`location'_`Y'"
				estadd local AGG "`AGG'"
				estadd local NC `e(N_clust)'
				local y = round(`e(r2_a_within)', .001)
				estadd local WR2 `y'
				estadd local Region_FE "`Region_FE'"
				estadd local Country_FE "`Country_FE'"
				estadd local Year_FE "X"
			restore

			// another regression with aggregated collapsed GDP = sum(GRP)
			if ("`file'" == "subnational_GRP") {
				local location iso3c
				local Y GRP
				local AGG "Country"
				local Region_FE ""
				local Country_FE "X"

				// aggregate / collapse GRP
				gcollapse (sum) GRP `light_var' `loc_var', by(iso3c year)
				foreach i in GRP `light_var' `loc_var' {
					replace `i' = . if `i' == 0
				}
				create_categ(iso3c year)
				gen ln_`light_var'_area = ln(`light_var'/`loc_var')
				gen ln_`Y' = ln(`Y')
				label variable ln_`light_var'_area "Log(`light_label' pixels/area)"
				label variable ln_`Y' "Log(Sum GRP)"
				gen covid_dummy = 1 if year >= 2020
				replace covid_dummy = 0 if !(year >= 2020)
				assert !mi(covid_dummy)
				label variable covid_dummy "Covid Dummy"
				pause checking the data prior to regression
				naomit
				
				// regression
				pause `file' `light_label' `income_group' COLLAPSED REGRESSION FIRST
				reghdfe ln_`Y' ln_`light_var'_area c.ln_`light_var'_area#covid_dummy, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
                eststo reg_`income_group'_`light_label'_`location'_`Y'_c
                estadd local AGG "`AGG'"
                estadd local NC `e(N_clust)'
                local y = round(`e(r2_a_within)', .001)
                estadd local WR2 `y'
                estadd local Region_FE "`Region_FE'"
                estadd local Country_FE "`Country_FE'"
                estadd local Year_FE "X"
				
				pause `file' `light_label' `income_group' COLLAPSED REGRESSION SECOND
				reghdfe ln_`Y' ln_`light_var'_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
                eststo reg_`income_group'_`light_label'_`location'_`Y'
                estadd local AGG "`AGG'"
                estadd local NC `e(N_clust)'
                local y = round(`e(r2_a_within)', .001)
                estadd local WR2 `y'
                estadd local Region_FE "`Region_FE'"
                estadd local Country_FE "`Country_FE'"
                estadd local Year_FE "X"
			}
		}
	}
}



foreach file in subnational_GRP sample_iso3c_year_pop_den__allvars2 {
	foreach light_label in VIIRS BM {
		foreach income_group in OECD n_O Glo {


            if ("`file'" == "sample_iso3c_year_pop_den__allvars2") {
				local location iso3c
				local Y WDI
				local AGG "Country"
				local Region_FE ""
				local Country_FE "X"
			}
			else if ("`file'" == "subnational_GRP") {
				local location region
				local Y GRP
				local AGG "Admin1"
				local Region_FE "X"
				local Country_FE ""
			}
			di "reg_`income_group'_`light_label'_`location'_`Y'"
			di "reg_`income_group'_`light_label'_`location'_`Y'_c"


			if ("`file'" == "subnational_GRP") {
				local location iso3c
				local Y GRP
				local AGG "Country"
				local Region_FE ""
				local Country_FE "X"
			}

			di "reg_`income_group'_`light_label'_`location'_`Y'"
			di "reg_`income_group'_`light_label'_`location'_`Y'_c"




		}
	}
}


/* EXPORT ----------- */

local i = 1

foreach Y in WDI GRP{
foreach location in region iso3c{
foreach light_label in VIIRS BM{

if (`i' == 1) {
    local addendum `"mgroups("Global" "Global" "OECD" "OECD" "Not OECD" "Not OECD", pattern(1 1 1 1 1 1 1 1 1 1) span prefix(\multicolumn{@span}{c}{) suffix(})) replace"'
}
else if (`i'!=1) {
    capture quietly macro drop addendum
	local addendum `"append"'
}

// we do not have WDI for regions:
if ("`Y'" == "WDI" & "`location'" == "region") {
    continue
}

// get panel labels:
    if (`i' == 1) {
        local panel_label "A: Country level, VIIRS"
    }
    if (`i' == 2) {
        local panel_label "B: Country level, BM"
    }
    if (`i' == 3) {
        local panel_label "C: Subnational level, VIIRS"
    }
    if (`i' == 4) {
        local panel_label "D: Subnational level, BM"
    }
    if (`i' == 5) {
        local panel_label "E: Country level, using GDP as summed subnational GRP, VIIRS"
    }
    if (`i' == 6) {
        local panel_label "F: Country level, using GDP as summed subnational GRP, BM"
    }

// output:
    esttab reg_Glo_`light_label'_`location'_`Y' reg_Glo_`light_label'_`location'_`Y'_c ///
    reg_OECD_`light_label'_`location'_`Y' reg_OECD_`light_label'_`location'_`Y'_c /// 
    reg_n_O_`light_label'_`location'_`Y' reg_n_O_`light_label'_`location'_`Y'_c ///
    using "$overleaf/all_log_levels.tex", ///
    posthead("\hline \\ \multicolumn{4}{l}{\textbf{Panel `panel_label'}} \\\\[-1ex]") ///
    fragment ///
    scalars("AGG Aggregation Level" "NC Number of Groups" "WR2 Adjusted Within R-squared" "Region_FE Region Fixed Effects" "Country_FE Country Fixed Effects" "Year_FE Year Fixed Effects") ///
    nomtitles nonumbers nolines ///
    b(3) se(3) ar2 star(* 0.10 ** 0.05 *** 0.01) sfmt(3) ///
    label booktabs nobaselevels  drop(_cons) ///
    `addendum'

local i = `i' + 1

}
}
}













