/* Do all log levels regressions (i.e. HWS regressions) */

pause off // CHANGE!!!!

est clear
clear	


// just basic DMSP vs. BM Dec at country level:
use "$input/iso3c_year_aggregation.dta", clear
label variable lndn "Log(DMSP pixels/area)"
label variable sum_pix_bm_dec_area "BM Dec. pixels/area"
quietly capture drop ln_sum_pix_bm_dec_area 
create_logvars "sum_pix_bm_dec_area"

// do the HWS regression for the same variable and same year as them:
bootstrap, rep(50) cluster(cat_iso3c) : ///
reghdfe ln_WDI lndn if year <= 2008 & !(inlist(iso3c, "GNQ", "BHR", "SGP", "HKG")), absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
	eststo reg_DMSP
	estadd local AGG "Country"
	estadd local NC `e(N_clust)'
	local y = round(`e(r2_a_within)', .001)
	estadd local WR2 `y'
	estadd local ADM1_FE ""
	estadd local Country_FE "X"
	estadd local Year_FE "X"

// do the BM regression
bootstrap, rep(50) cluster(cat_iso3c) : ///
reghdfe ln_WDI ln_sum_pix_bm_dec_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
	eststo reg_VIIRS
	estadd local AGG "Country"
	estadd local NC `e(N_clust)'
	local y = round(`e(r2_a_within)', .001)
	estadd local WR2 `y'
	estadd local ADM1_FE ""
	estadd local Country_FE "X"
	estadd local Year_FE "X"

// output:
    esttab reg_DMSP reg_VIIRS using "$overleaf/basic_DMSP_vs_VIIRS.tex", ///
    fragment ///
    scalars("AGG Aggregation Level" "NC Number of Groups" "WR2 Adjusted Within R-squared" "ADM1_FE ADM1 Fixed Effects" "Country_FE Country Fixed Effects" "Year_FE Year Fixed Effects") ///
    nonumbers ///
    b(3) se(3) ar2 star(* 0.10 ** 0.05 *** 0.01) sfmt(3) ///
    label booktabs nobaselevels  drop(_cons) replace

/* Do all log levels regressions */
pause off // CHANGE!!!!

est clear
clear	

// macro stores which nonOECD countries are present in the subnational GRP data
capture macro drop isos_in_subnat

foreach file in adm1_year_aggregation iso3c_year_aggregation {
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

			// !!!!!!!!!!! PERHAPS CHANGE BACK: THIS BELOW CODE RESTRICTED ATTENTION TO
			// NON-OECD COUNTRIES (BRICS MAINLY) THAT WE HAVE SUBNATIONAL DATA ON

			// if ("`income_group'" == "n_O" & "`file'" == "iso3c_year_aggregation") {
			// 	gen to_keep = "no"
			// 	foreach i in `isos_in_subnat' {
			// 		replace to_keep = "yes" if iso3c == "`i'"
			// 	}
			// 	replace to_keep = "" if mi(iso3c)
			// 	pause checking whether the to_keep variable is labeled correctly
			// 	keep if to_keep == "yes"
			// 	drop to_keep        
			// }

			// define local macros that will help us label & run the regression

			if ("`light_label'" == "VIIRS") {
				local light_var del_sum_pix
				local loc_var del_sum_area
			}
			if ("`light_label'" == "BM") {
				local light_var sum_pix_bm_dec
				local loc_var pol_area
			}
			label variable ln_`light_var'_area "Log(`light_label' pixels/area)"
			pause u9090uu90r0

			if ("`file'" == "iso3c_year_aggregation") {
				local location iso3c
				local Y WDI
				local AGG "Country"
				local ADM1_FE ""
				local Country_FE "X"
				label variable ln_`Y' "Log(GDP, LCU)"
			}
			else if ("`file'" == "adm1_year_aggregation") {
				local location ADM1
				local Y GRP
				local AGG "Admin1"
				local ADM1_FE "X"
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
				if ("`file'" == "adm1_year_aggregation" & "`income_group'" == "n_O") {
					levelsof iso3c, local(isos_in_subnat)
				}


				// regression
				pause `file' `light_label' `income_group' FIRST REGRESSION
				bootstrap, rep(50) cluster(cat_`location') : ///
				reghdfe ln_`Y' ln_`light_var'_area c.ln_`light_var'_area#covid_dummy, absorb(cat_`location' cat_year) vce(cluster cat_`location')
				eststo reg_`income_group'_`light_label'_`location'_`Y'_c
				di "reg_`income_group'_`light_label'_`location'_`Y'_c"
				estadd local AGG "`AGG'"
				estadd local NC `e(N_clust)'
				local y = round(`e(r2_a_within)', .001)
				estadd local WR2 `y'
				estadd local ADM1_FE "`ADM1_FE'"
				estadd local Country_FE "`Country_FE'"
				estadd local Year_FE "X"

				pause `file' `light_label' `income_group' SECOND REGRESSION
				bootstrap, rep(50) cluster(cat_`location') : ///
				reghdfe ln_`Y' ln_`light_var'_area, absorb(cat_`location' cat_year) vce(cluster cat_`location')
				eststo reg_`income_group'_`light_label'_`location'_`Y'
				di "reg_`income_group'_`light_label'_`location'_`Y'"
				estadd local AGG "`AGG'"
				estadd local NC `e(N_clust)'
				local y = round(`e(r2_a_within)', .001)
				estadd local WR2 `y'
				estadd local ADM1_FE "`ADM1_FE'"
				estadd local Country_FE "`Country_FE'"
				estadd local Year_FE "X"
			restore

			// another regression with aggregated collapsed GDP = sum(GRP)
			if ("`file'" == "adm1_year_aggregation") {
				local location iso3c
				local Y GRP
				local AGG "Country"
				local ADM1_FE ""
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
				bootstrap, rep(50) cluster(cat_iso3c) : ///
				reghdfe ln_`Y' ln_`light_var'_area c.ln_`light_var'_area#covid_dummy, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
                eststo reg_`income_group'_`light_label'_`location'_`Y'_c
                estadd local AGG "`AGG'"
                estadd local NC `e(N_clust)'
                local y = round(`e(r2_a_within)', .001)
                estadd local WR2 `y'
                estadd local ADM1_FE "`ADM1_FE'"
                estadd local Country_FE "`Country_FE'"
                estadd local Year_FE "X"
				
				pause `file' `light_label' `income_group' COLLAPSED REGRESSION SECOND
				bootstrap, rep(50) cluster(cat_iso3c) : ///
				reghdfe ln_`Y' ln_`light_var'_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
                eststo reg_`income_group'_`light_label'_`location'_`Y'
                estadd local AGG "`AGG'"
                estadd local NC `e(N_clust)'
                local y = round(`e(r2_a_within)', .001)
                estadd local WR2 `y'
                estadd local ADM1_FE "`ADM1_FE'"
                estadd local Country_FE "`Country_FE'"
                estadd local Year_FE "X"
			}
		}
	}
}



foreach file in adm1_year_aggregation iso3c_year_aggregation {
	foreach light_label in VIIRS BM {
		foreach income_group in OECD n_O Glo {


            if ("`file'" == "iso3c_year_aggregation") {
				local location iso3c
				local Y WDI
				local AGG "Country"
				local ADM1_FE ""
				local Country_FE "X"
			}
			else if ("`file'" == "adm1_year_aggregation") {
				local location ADM1
				local Y GRP
				local AGG "Admin1"
				local ADM1_FE "X"
				local Country_FE ""
			}
			di "reg_`income_group'_`light_label'_`location'_`Y'"
			di "reg_`income_group'_`light_label'_`location'_`Y'_c"


			if ("`file'" == "adm1_year_aggregation") {
				local location iso3c
				local Y GRP
				local AGG "Country"
				local ADM1_FE ""
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
foreach location in ADM1 iso3c{
foreach light_label in VIIRS BM{

if (`i' == 1) {
    local addendum `"mgroups("Global" "Global" "OECD" "OECD" "Not OECD" "Not OECD", pattern(1 1 1 1 1 1 1 1 1 1) span prefix(\multicolumn{@span}{c}{) suffix(})) replace"'
}
else if (`i'!=1) {
    capture quietly macro drop addendum
	local addendum `"append"'
}

// we do not have WDI for ADM1s:
if ("`Y'" == "WDI" & "`location'" == "ADM1") {
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
    scalars("AGG Aggregation Level" "NC Number of Groups" "WR2 Adjusted Within R-squared" "ADM1_FE ADM1 Fixed Effects" "Country_FE Country Fixed Effects" "Year_FE Year Fixed Effects") ///
    nomtitles nonumbers nolines ///
    b(3) se(3) ar2 star(* 0.10 ** 0.05 *** 0.01) sfmt(3) ///
    label booktabs nobaselevels  drop(_cons) ///
    `addendum'

local i = `i' + 1

}
}
}













