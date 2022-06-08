// A paper was published that showed that NTL diminished at higher GDP levels.
// This regression puts NTL on the LHS and GDP and GDP^2 on the RHS with fixed
// effects to see whether this is true. 

foreach agg_level in cat_iso3c cat_ADM1 {
	est clear
	if ("`agg_level'" == "cat_iso3c") {
		use "$input/iso3c_year_aggregation.dta", clear
		loc AGG "Country"
		label variable ln_WDI "Log(GDP)"
		rename ln_WDI gdp_var
	}
	if ("`agg_level'" == "cat_ADM1") {
		use "$input/adm1_year_aggregation.dta", clear
		loc AGG "Admin 1"
		label variable ln_GRP "Log(GRP)"
		rename ln_GRP gdp_var
	}
	
	keep_oecd iso3c
	
	loc i = 1
	loc j = 1
	loc olsregs ""
	loc quantregs ""

	label variable ln_sum_pix_bm "Log(BM pixels)"
	label variable ln_sum_pix_bm "Log(BM pixels)"
	label variable ln_del_sum_pix "Log(VIIRS pixels)"

	foreach var in ln_sum_pix_bm ln_sum_pix_bm ln_del_sum_pix{
		reghdfe `var' gdp_var c.gdp_var#c.gdp_var, absorb(`agg_level' cat_year) vce(cluster `agg_level')
        eststo r`i'_`agg_level'
        estadd local AGG "`AGG'"
        estadd local NC `e(N_clust)'
        local y = round(`e(r2_a_within)', .001)
        estadd local WR2 `y'
        estadd local ADM1_FE "X"
        estadd local Country_FE ""
        estadd local Year_FE "X"
		
		loc olsregs `olsregs' r`i'_`agg_level'

		foreach quant in .25 .5 .75 {
			// quantile reg with GDP as Y term
			xtqreg gdp_var `var' i.cat_year, quantile(`quant') i(`agg_level')
			eststo qr`i'`j'_`agg_level'
			estadd local AGG "`AGG'"
			estadd local ADM1_FE "X"
			estadd local Country_FE ""
			estadd local Year_FE "X"

			loc quantregs `quantregs' qr`i'`j'_`agg_level'
			loc j = `j' + 1
		}
		loc i = `i' + 1
	}

	/* EXPORT ----------- */

	esttab `olsregs' using "$overleaf/quadratic_`agg_level'_1.tex", replace f ///
		b(3) se(3) ar2 label star(* 0.10 ** 0.05 *** 0.01) ///
		booktabs ///
		scalars("AGG Aggregation Level" "NC Number of Groups" "WR2 Adjusted Within R-squared" "ADM1_FE Admin. 1 Fixed Effects" "Country_FE Country Fixed Effects" "Year_FE Year Fixed Effects") ///
		nobaselevels  drop(_cons)

	esttab `quantregs' using "$overleaf/quadratic_`agg_level'_2.tex", replace f ///
		b(3) se(3) ar2 label star(* 0.10 ** 0.05 *** 0.01) ///
		booktabs ///
		scalars("AGG Aggregation Level" "ADM1_FE Admin. 1 Fixed Effects" "Country_FE Country Fixed Effects" "Year_FE Year Fixed Effects") ///
		nobaselevels  drop(*.cat_year)


}
