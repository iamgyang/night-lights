// RUN REGRESSIONS --------------------------------

eststo clear
foreach week_restriction in " " {
foreach treat_var in affected deaths {
// helps label the column groupings:
	if ("`treat_var'" == "affected") {
		local mg "Natural Disasters"
	}
	else if ("`treat_var'" == "deaths") {
		local mg "War"
	}
	
	local mgroups "`mgroups' `"`mg'"'"
foreach pctile in 99 90 60 80 40 20 {
	
	// we do not do the 99th percentile for natural disasters because the sample 
	// is way too small
	if ("`treat_var'" == "affected" & `pctile' == 99) {
		continue
	}
	// get dataset
	use "$input/`treat_var'_disaster_event_study_`pctile'_percentile_`week_restriction'.dta", clear
	label variable tr "Month $\ge$ cutoff"

	// count the number of ADM2 regions that were treated and store into local, x:
	preserve
		drop if missing(tr) | tr == 0
		quietly tab cat_objectid
		local x `r(r)'
	restore

	// the tr variable is 1 if we are in a month where the treatment is greater than the percentile cutoff.
	eststo: reghdfe ln_del_sum_pix_area tr, absorb(cat_year cat_objectid cat_month) vce(cluster cat_objectid)
		// number of ADM2 clusters
		estadd local NC `e(N_clust)'
		// number of ADM2 regions that were treated
		estadd local TC `x'
		// Within R squared
		local y= round(`e(r2_a_within)', .001)
		estadd local WR2 `y'
	
	if (("`treat_var'" == "deaths" & `pctile' == 99)|("`treat_var'" == "affected" & `pctile' == 90)) {
		local pattern "`pattern' 1"
	}
	else if !(("`treat_var'" == "deaths" & `pctile' == 99)|("`treat_var'" == "affected" & `pctile' == 90)) {
		local pattern "`pattern' 0"
	}
	local mlabel "`mlabel' `pctile'\textsuperscript{th}"
}
}
}

di `"`mgroups'"'
di "`pattern'"

esttab using "$overleaf/regression_TEST.tex", replace f ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
label booktabs nonotes ///
mlabel(`mlabel') ///
scalars("NC Number of ADM2 Regions" "TC Number of Treated ADM2 Regions" "WR2 Adjusted Within R-squared") ///
mgroups(`mgroups', pattern("`pattern'") prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
drop(_cons)




