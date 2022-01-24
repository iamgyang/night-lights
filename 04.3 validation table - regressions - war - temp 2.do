// RUN REGRESSIONS --------------------------------

foreach week_restriction in " " {
	foreach treat_var in affected deaths {
		// !! clears out our stored regressions:
		eststo clear
		local mlabel ""
		foreach pctile in 20 40 60 80 90 99 {
			// we do not do the 99th percentile for natural disasters because the sample 
			// is way too small
			if ("`treat_var'" == "affected" & `pctile' == 99) {
				continue
			}
			// get dataset
			use "$input/`treat_var'_disaster_event_study_`pctile'_percentile_`week_restriction'.dta", clear
			label variable tr "$\ge$ cutoff `treat_var'"
			
			// for eventdd, we want tr to be missing if there is no data.
			// here, we put tr to be 0 as the reference for where there is no data. (ask justin to confirm)
			replace tr = 0 if missing(tr)
			
			// count the number of ADM2 regions that were treated and store into local, x:
			preserve
			drop if missing(tr) | tr == 0 | missing(ln_del_sum_pix_area)
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

			local mlabel "`mlabel' `pctile'\textsuperscript{th}"
		}
		esttab using "$overleaf/`treat_var'_response_`week_restriction'.tex", replace f ///
			b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
			label booktabs nonotes ///
			mlabel(`mlabel') ///
			scalars("NC Number of ADM2 Regions" "TC Number of Treated ADM2 Regions" "WR2 Adjusted Within R-squared") ///
			drop(_cons)
	}
}



















