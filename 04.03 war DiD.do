// do all war difference in difference regressions & event studies

local sample 0
pause off

// WARNINGS -----------------------------------------------
if (`sample' == 1) {
	di "YOU ARE USING A TEST SAMPLE OF THE DATA"
}
else if (`sample' != 1) {
	di "YOU ARE USING ALL THE DATA"
}

// DEFINE CUTOFF FOR TREATMENT ----------------------------------------------
foreach light_label in VIIRS BM {
foreach treat_var in deaths {
	foreach pctile in 50 75 90 95 98 99 {
		foreach week_restriction in "3wk" " " {
			if ("`light_label'" == "VIIRS") {
				local light_var ln_del_sum_pix_area
			}
			if ("`light_label'" == "BM") {
				local light_var ln_sum_pix_bm_area
			}

			if (`sample' == 1) {
				use "$input/sample_war_nat_disaster_event_prior_to_cutoff.dta", clear
				/* drop if we don't have night lights data */
				drop if mi(`light_var')
			}
			else {
				use "$input/war_nat_disaster_event_prior_to_cutoff.dta", clear	
				/* drop if we don't have night lights data */
				drop if mi(`light_var')
			}
			
			// get percentile values
			preserve
			drop if `treat_var' <= 0 | missing(`treat_var')
			centile `treat_var', centile(`pctile')
			local perc `r(c_1)'
			restore

			// just display the percentile so that I can diagnose problems
			foreach n in 1 1 1 1 1 1 1 {
				di `perc'
			}
			
			// treatment value if greater than this percentile value
			gen tr = 1 if `treat_var' >= `perc'

			// do not define treatment for any event that lasted less than X week's time
			if ("`week_restriction'" == "3wk") {
				replace tr = 0 if `treat_var'_dur <= 3*7
			}
			replace tr = 0 if `treat_var' < `perc'
			replace tr = . if missing(`treat_var')

			// countries treated:
			bys objectid: gegen tr_at_all = max(tr)
			drop if missing(tr_at_all)

			// get treatment start date
			bys objectid: gegen tr_year = min(year) if tr == 1
			bys objectid: gegen tr_month = min(month) if tr == 1
			assert tr_year == . if tr_at_all == .
			assert tr_month == . if tr_at_all == .

			// ignore if we don't have objectID
			drop if missing(objectid)

			// each country should only have 1 treatment start date
			preserve
			keep objectid tr_year tr_month
			gduplicates drop
			drop if mi(tr_year) & mi(tr_month)
			check_dup_id "objectid"
			restore

			bys objectid: fillmissing tr_year tr_month
			br objectid year month tr tr_year tr_month
			assert tr_year != . if tr_at_all == 1
			assert tr_month != . if tr_at_all == 1

			keep `light_var' objectid year month tr tr_year tr_month tr_at_all cat_year cat_month cat_objectid
			g ttt = 12*(year - tr_year) + (month-tr_month)

			gen post_tr = 1 if ttt >= 0
			replace post_tr = 0 if ttt < 0 | missing(ttt)

			label variable objectid "ADM2"
			label variable year "year"
			label variable month "month"
			label variable `light_var' "Log lights / area"
			label variable tr "Whether the country was above `perc' `treat_var' (`pctile' percentile) this month"
			label variable tr_at_all "Did the country experience >`perc' `treat_var' in a month at all?"
			label variable tr_year "Year of event start"
			label variable tr_month "Month of event start"
			label variable ttt "Time to event start (months)"
			label variable post_tr "Is this after event start?"

			save "$input/`treat_var'_`light_label'_disaster_event_study_`pctile'_percentile_`week_restriction'.dta", replace
		}
	}
}
}

// RUN REGRESSIONS --------------------------------

// first delete all the regression table files:
foreach i in affected_response_1 sum_pix_affected_response_1 deaths_response_1 sum_pix_deaths_response_1  {
	noisily capture erase "$overleaf/`i'.xls"
	noisily capture erase "$overleaf/`i'.txt"
	noisily capture erase "$overleaf/`i'.tex"
}

foreach light_label in VIIRS BM {
foreach week_restriction in "3wk" " " {
	foreach treat_var in deaths {
		foreach pctile in  50 75 90 95 98 99 { 
			if ("`light_label'" == "VIIRS") {
				local light_var ln_del_sum_pix_area
			}
			if ("`light_label'" == "BM") {
				local light_var ln_sum_pix_bm_area
			}

			pause `week_restriction' `treat_var' `pctile'
			use "$input/`treat_var'_`light_label'_disaster_event_study_`pctile'_percentile_`week_restriction'.dta", clear

			keep if ((ttt <= 30) & (ttt>=-30)) | (missing(ttt))

			#delimit ;
			eventdd `light_var', hdfe absorb(cat_year cat_objectid cat_month) 
			timevar(ttt) ci(rcap) cluster(cat_objectid) inrange lags(30) leads(30) 
			graph_op(ytitle("Log Lights / Area") xlabel(-30(5)30))
			;
			#delimit cr
			gr export "$overleaf/sum_pix_event_study_`light_label'_`treat_var'_`pctile'_`week_restriction'.png", as(png) width(3000) height(2000) replace

			outreg2 using "$output/`treat_var'_response_1.tex", append ///
				label dec(3) ///
				bdec(3) addstat(Countries, e(N_clust), ///
				Adjusted Within R-squared, e(r2_a_within), ///
				Within R-squared, e(r2_within)) ///
				title("`light_label' `treat_var'" "(`pctile' percentile) `week_restriction'")
			
			eststo: reghdfe `light_var' post_tr, absorb(cat_year cat_objectid cat_month) vce(cluster cat_objectid)
			estadd local NC `e(N_clust)'
			local y= round(`e(r2_a_within)', .001)
			estadd local WR2 `y'

			esttab using "$overleaf/sum_pix_`treat_var'_response_1.tex", append f  ///
				b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
				label booktabs nomtitle nobaselevels collabels(none) ///
				scalars("NC Number of Countries" "WR2 Adjusted Within R-squared") ///
				title("`light_label' `treat_var'" "(`pctile' percentile) `week_restriction'") ///
				sfmt(3)

		}
	}
}
}

cls
foreach week_restriction in "3wk" " " {
	foreach treat_var in affected deaths {
		foreach pctile in  50 75 90 95 98 { 

			if ("`treat_var'" == "affected") {
				loc treat_var "Natural Disaster"
			}
			else if ("`treat_var'" == "deaths") {
				loc treat_var "Wars"
			}

			di "`treat_var' `pctile'th Percentile `week_restriction'"
			di "`treat_var' `pctile'th Percentile `week_restriction'"


		}
	}
}


