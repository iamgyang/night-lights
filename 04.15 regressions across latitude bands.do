// import data
foreach XVAR in ln_sum_pix_bm_dec_area ln_sum_pix_bm_area ln_del_sum_pix_area {

	// create table to store output
		clear
		set obs 1
		gen point = 999999999
		tempfile base
		save `base'
		use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear
		local lab: variable label `XVAR'
		local lab = subinstr("`lab'", " pixels / area", "",.)
		local lab = subinstr("`lab'", "Log ", "",.)
		local lab = subinstr("`lab'", "BM", "Black Marble",.)
		local lab = subinstr("`lab'", "Dec.", "December",.)
		di "`lab'"
		keep iso3c year ln_WDI `XVAR'
		naomit
		create_categ iso3c year
		mmerge iso3c using "$input/lats and longs.dta"
		naomit
		drop _merge
		sort latitude
		egen n = group(latitude)
		sort n year

	// loop across latitude bands
		foreach k of numlist 1(18)144 {
			di `k'
			di `k' + 18
			di "---------"
			preserve
				
			// run regression on specific latitude band
				keep if n > `k' & n <= `k'+18
				reghdfe ln_WDI `XVAR' c.`XVAR'#c.`XVAR', absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
				
			// get the upper and lower confidence intervals and the point estimate
				matrix list r(table)
				matrix test = r(table)
				foreach xyz in b ll ul df {
					matrix `xyz' = test["`xyz'", "`XVAR'"]
					loc `xyz' = `xyz'[1,1]
				}
				foreach xyz in b ll ul df {
					matrix `xyz'_sq = test["`xyz'", "c.`XVAR'#c.`XVAR'"]
					loc `xyz'_sq = `xyz'_sq[1,1]
				}
			// get latitude band
				summarize latitude
				local latitude_start `r(min)'
				local latitude_end `r(max)'

			// store coefficients into my table
				clear
				set obs 1
				gen point = `b'
				gen ul = `ul'
				gen ll = `ll'
				gen lat_higher = `latitude_end'
				gen lat_lower = `latitude_start'
				gen lat_mid = (`latitude_start' + `latitude_end')/2
				
				gen point_sq = `b_sq'
				gen ul_sq = `ul_sq'
				gen ll_sq = `ll_sq'
				
				gen num_countries = `df' + 1
				append using `base'
				save `base', replace

			restore
		}
	clear
	use `base'
	naomit

// GRAPH 1: coefficient on the degree-1 term:
	# delimit ;
	twoway (line point lat_mid) 
	(scatter point lat_mid) 
	(rcap ul ll lat_mid, lcolor(%50) msize(4-pt))
	, ytitle("") xtitle(Latitude) title(`lab') subtitle(95% confidence intervals of HWS regression coefficient)
	legend(off)
	;
	#delimit cr

	gr export "$overleaf/parameter stability lat long `XVAR' degree 1 term.png", replace

// GRAPH 1: coefficient on the degree-2 term:
	# delimit ;
	twoway (line point_sq lat_mid) 
	(scatter point_sq lat_mid) 
	(rcap ul_sq ll_sq lat_mid, lcolor(%50) msize(4-pt))
	, ytitle("") xtitle(Latitude) title(`lab') subtitle(95% confidence intervals of HWS regression coefficient)
	legend(off)
	;
	#delimit cr

	gr export "$overleaf/parameter stability lat long `XVAR' degree 2 term.png", replace

}

// LINEAR FIT -----------------------------------------------------------

// import data
foreach XVAR in ln_sum_pix_bm_dec_area ln_sum_pix_bm_area ln_del_sum_pix_area {

	// create table to store output
		clear
		set obs 1
		gen point = 999999999
		tempfile base
		save `base'
		use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear
		local lab: variable label `XVAR'
		local lab = subinstr("`lab'", " pixels / area", "",.)
		local lab = subinstr("`lab'", "Log ", "",.)
		local lab = subinstr("`lab'", "BM", "Black Marble",.)
		local lab = subinstr("`lab'", "Dec.", "December",.)
		di "`lab'"
		keep iso3c year ln_WDI `XVAR'
		naomit
		create_categ iso3c year
		mmerge iso3c using "$input/lats and longs.dta"
		naomit
		drop _merge
		sort latitude
		egen n = group(latitude)
		sort n year

	// loop across latitude bands
		foreach k of numlist 1(18)144 {
			di `k'
			di `k' + 18
			di "---------"
			preserve
				
			// run regression on specific latitude band
				keep if n > `k' & n <= `k'+18
				reghdfe ln_WDI `XVAR', absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
				
			// get the upper and lower confidence intervals and the point estimate
				matrix list r(table)
				matrix test = r(table)
				foreach xyz in b ll ul df {
					matrix `xyz' = test["`xyz'", "`XVAR'"]
					loc `xyz' = `xyz'[1,1]
				}

			// get latitude band
				summarize latitude
				local latitude_start `r(min)'
				local latitude_end `r(max)'

			// store coefficients into my table
				clear
				set obs 1
				gen point = `b'
				gen ul = `ul'
				gen ll = `ll'
				gen lat_higher = `latitude_end'
				gen lat_lower = `latitude_start'
				gen lat_mid = (`latitude_start' + `latitude_end')/2
				
				gen num_countries = `df' + 1
				append using `base'
				save `base', replace

			restore
		}
	clear
	use `base'
	naomit

// GRAPH 1: coefficient on the degree-1 term:
	# delimit ;
	twoway (line point lat_mid) 
	(scatter point lat_mid) 
	(rcap ul ll lat_mid, lcolor(%50) msize(4-pt))
	, ytitle("") xtitle(Latitude) title(`lab') subtitle(95% confidence intervals of HWS regression coefficient)
	legend(off)
	;
	#delimit cr

	gr export "$overleaf/parameter stability lat long `XVAR' degree 1 term - LINEAR.png", replace

}

