// This produces regressions of how NTL are associated with covid stringency at
// a country-month level.

// for subnational and national level:
// regress feols(log(light) – log(light in same month in 2019) ~ stringency|province + month)

// prep data oxford COVID stringency
clear
set obs 2
gen iso3c = "N/A"
gen year = 2019 if _n == 1
replace year = 2018 if _n == 2
gen stringencyindex = 0
tempfile base
save `base'
use "$input/covid_oxford_cleaned.dta", clear
gcollapse (mean) stringencyindex, by(month iso3c year)
append using `base'
fillin iso3c year month
replace stringencyindex = 0 if mi(stringencyindex) & (year == 2019 | year == 2018)
naomit
// assert !mi(stringencyindex)
tempfile ox_str
save `ox_str'

// run regressions
// foreach agg_level in "cat_iso3c" "cat_ADM1" {
	foreach income_group in "Global" "OECD" "Not_OECD" {
		foreach light_var in "VIIRS" "BM" {

			if ("`light_var'"== "VIIRS") {
				use "$input/iso3c_month_viirs.dta", clear
				gen del_sum_pix_area = del_sum_pix/del_sum_area
				local light del_sum_pix_area
				label variable `light' "VIIRS (cleaned) pixels / area"
			}
			else if ("`light_var'"== "BM") {
				use "$input/bm_iso3c_month.dta", clear
				gen sum_pix_bm_area = sum_pix_bm / pol_area
				local light sum_pix_bm_area
				label variable `light' "BM pixels / area"
			}

			create_logvars "`light'"

			// create annual differences (e.g. Jan 2017 minus Jan 2016 or Q1 2021 minus Q1 2020)
			foreach var of varlist ln_`light' {
				sort iso3c month year
				generate g_an_`var' = `var' - `var'[_n-1] if ///
					iso3c == iso3c[_n-1] & ///
					(year - 1) == (year[_n-1]) & ///
					month == month[_n-1]
				pause generate annual differences
				loc lab: variable label `var'
				di "`lab'"
				label variable g_an_`var' "Diff. annual `lab'"
			}

			//	merge in with oxford stringency
			mmerge iso3c year month using `ox_str'
			pause merged with oxford
			
            // make ISO3C and MONTH categorical variables
            create_categ(iso3c month year)
			
			//	income group restriction:
			if ("`income_group'" == "OECD") {
				keep_oecd iso3c
			}
			if ("`income_group'" == "Not_OECD") {
				drop_oecd iso3c
			}
			
			
			pause PRIOR TO REGRESSION
			reghdfe g_an_ln_`light' stringencyindex, absorb(cat_iso3c cat_month) vce(cluster cat_iso3c)
			estadd local NC `e(N_clust)'
			local y= round(`e(r2_a_within)', .001)
			estadd local WR2 `y'
			eststo q`income_group'_`light_var'
		}
	}


/* EXPORT ----------- */

esttab qGlobal_VIIRS qOECD_VIIRS qNot_OECD_VIIRS using "$overleaf/covid_stringency.tex", ///
posthead("\hline\hline  \\ \multicolumn{4}{l}{\textbf{Panel A: Country level, VIIRS}} \\\\[-1ex]") ///
fragment ///
mgroups("Global" "OECD" "Not OECD", pattern(1 1 1) span prefix(\multicolumn{@span}{c}{) suffix(})) ///
scalars("NC Number of Countries" "WR2 Adjusted Within R-squared") ///
nomtitles ///
b(3) se(3) ar2 star(* 0.10 ** 0.05 *** 0.01 **** 0.01) sfmt(3) ///
label booktabs nobaselevels  drop(_cons) ///
replace

esttab qGlobal_BM qOECD_BM qNot_OECD_BM using "$overleaf/covid_stringency.tex", ///
posthead("\hline\hline \\ \multicolumn{4}{l}{\textbf{Panel B: Country level, Black Marble (BM)}} \\\\[-1ex]") ///
fragment ///
append ///
scalars("NC Number of Countries" "WR2 Adjusted Within R-squared") ///
nomtitles nonumbers nolines ///
b(3) se(3) ar2 star(* 0.10 ** 0.05 *** 0.01 **** 0.01) sfmt(3) ///
label booktabs nobaselevels drop(_cons)
