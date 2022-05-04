global datasets pwt mad wdi bm dmsp

// first, get a dataset of country-level "night-lights-imputed" GDP. then, feed
// this into Dev's code to get the beta convergence graphs.

use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear

// black marble December 
keep ln_WDI_ppp ln_sum_pix_bm_dec_area ln_sum_light_dmsp_div_area cat_iso3c cat_year year iso3c
reghdfe ln_WDI_ppp ln_sum_pix_bm_dec_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
predict ln_gdp_bm

// DMSP
reghdfe ln_WDI_ppp ln_sum_light_dmsp_div_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
predict ln_gdp_dmsp

// dev's code requires us to start unlogged w/ GDP per capita
g wdi = exp(ln_WDI_ppp)
g bm = exp(ln_gdp_bm)
g dmsp = exp(ln_gdp_dmsp)

keep wdi bm dmsp iso3c year
rename (iso3c year) (ccode year)

tempfile light
save `light'

// Below is Dev's code, with some of my modifications.

/* This file loads the raw data from the noted sources, cleans the relevant
variables, and saves this combined dataset for analysis in the subsequent
scripts. */

*****************
*** PREP DATA ***
*****************
	
	*** Load Maddison data which can be downloaded from: https://www.rug.nl/ggdc/historicaldevelopment/maddison/
		tempfile maddison
		use "$raw_data/National Accounts/mpd2020.dta", clear
		rename (countrycode country gdppc pop) (ccode country mad mad_pop)
		drop if year <1950
		*** Drop former countries & UAE (data severely messed up)
			drop if ccode == "ARE" // UAE
			drop if ccode == "PRI" // Puerto Rico
			drop if ccode == "SUN" // Former USSR
			drop if ccode == "CSK" // Czechoslovakia
			drop if ccode == "YUG" // Former Yugoslavia
		replace mad_pop = mad_pop/1000
		save `maddison'
		
	*** Load PWT data which can be downloaded from: https://www.rug.nl/ggdc/productivity/pwt/	
		use "$raw_data/National Accounts/pwt100.dta", clear
		rename countrycode ccode
		keep country ccode year pop rgdpe 
		rename (pop rgdpe) (pwt_pop pwt)
		foreach var in pwt {
			replace `var' = `var'/pwt_pop
		}
		drop if missing(pwt_pop)
		
	*** Add in Maddison and WDI
		mmerge ccode year using `maddison'
		mmerge ccode year using `light'
		drop _merge

	*** Light GDP and WDI GDP are not yet per capita -- PWT population is in Millions:
		foreach var in bm dmsp wdi {
			replace `var' = `var'/(pwt_pop*10^6)
		}
		
		// pause lets check USA GDP per capita across datasets

	*** Oil-producers from IMF (http://datahelp.imf.org/knowledgebase/articles/516096-which-countries-comprise-export-earnings-fuel-a)
		gen oil = ccode == "DZA" | ///
			ccode == "AGO" | ///
			ccode == "AZE" | ///
			ccode == "BHR" | ///
			ccode == "BRN" | ///
			ccode == "TCD" | ///
			ccode == "COG" | ///
			ccode == "ECU" | ///
			ccode == "GNQ" | ///
			ccode == "GAB" | ///
			ccode == "IRN" | ///
			ccode == "IRQ" | ///
			ccode == "KAZ" | ///
			ccode == "KWT" | ///
			ccode == "NGA" | ///
			ccode == "OMN" | ///
			ccode == "QAT" | ///
			ccode == "RUS" | ///
			ccode == "SAU" | ///
			ccode == "TTO" | ///
			ccode == "TKM" | ///
			ccode == "ARE" | ///
			ccode == "VEN" | ///
			ccode == "YEM" | ///
			ccode == "LBY" | ///
			ccode == "TLS" | ///
			ccode == "SDN"
		gen nooil = 1-oil
		
	*** Small countries
		foreach data in pwt mad {
			gen big_`data' = `data'_pop>=1 if !missing(`data'_pop)
		}
			
	*** Restrict sample
		foreach var in pwt mad {
			replace `var' = . if big_`var'==0
		}
		drop if oil==1
		keep ccode country year $datasets *pop* 
		
	*** World Bank classifications downloaded from: https://datahelpdesk.worldbank.org/knowledgebase/articles/906519-world-bank-country-and-lending-groups
		preserve
			import excel "$raw_data/National Accounts/OGHIST.xlsx", sheet("Country Analytical History") cellrange(A5:AF229) clear
			rename A ccode
			rename B country
			rename D group1990
			drop if _n<8
			keep ccode country group1990
			tempfile groups
			save `groups', replace
		restore
		mmerge ccode using `groups', unmatched(master)
		drop _merge
save "$output/combined_data.dta", replace	



/* This do-file takes the data from "01 Prepare Data", calculates beta
convergence coefficients, and produces the associated graph. */

*************************
*** BETA COEFFICIENTS ***
*************************

	*** Load data
		use "$output/combined_data.dta", clear
		capture drop _merge
		drop *_pop
		reshape wide $datasets, i(ccode country) j(year)
		*drop if pwt1990==.|wdi1990==.|mad1990==.
		
	*** Cycle through regressions
		local j = 1	
		foreach data in $datasets {			
			// Customize window by dataset
			if "`data'" == "bm" {
				local firstyear = 2013
				local lastyear = 2018
			}
            else if "`data'" == "dmsp" {
                local firstyear = 1992
				local lastyear = 2012
            }
			else if "`data'" == "wdi" {
				local firstyear = 1992
				local lastyear = 2018
			}
			else if "`data'" == "pwt" {
				local firstyear = 1950 
				local lastyear = 2018
			}
			else if "`data'" == "mad" {
				local firstyear = 1950 
				local lastyear = 2018
			}
			local endyear = `lastyear' - 1 		
				forval startyear = `firstyear'(1)`endyear' {
					gen outcome = (log(`data'`lastyear'/`data'`startyear')/(`lastyear' - `startyear'))*100
					gen initial = log(`data'`startyear')
					qui reg outcome initial, robust  
					preserve
						clear
						set obs 1
						tempfile file`j'
						gen measure = "`data'"
						gen beta = _b[initial]
						gen se = _se[initial]
						gen lower = _b[initial] - invttail(`e(df_r)',0.025)*_se[initial]
						gen upper = _b[initial] + invttail(`e(df_r)',0.025)*_se[initial]
						gen tstat = _b[initial]/_se[initial]
						gen pval =2*ttail(`e(df_r)',abs(tstat))
						gen n = `e(N)'
						gen startyear = `startyear'
						save `file`j''
					restore
					drop outcome initial
					local ++ j
				}
		}
	
	*** Combine results
		clear
		local jminus1 = `j' - 1
		forval i = 1/`jminus1' {
			append using `file`i''
		}
		
	*** Stagger years for graph
    	gen startyear2 = startyear + .1
		gen startyear3 = startyear + .2
        gen startyear4 = startyear + .3
        gen startyear5 = startyear + .4
	
		#delimit ;
		tw  (rcap lower upper startyear if measure == "mad" & startyear >=1960 , lcolor(gs10)) 	
			(sc beta startyear if measure == "mad" & startyear >=1960 , mcolor(plg1))	
			(rcap lower upper startyear2 if measure == "pwt" & startyear >=1960 , lcolor(gs10)) 	
			(sc beta startyear2 if measure == "pwt" & startyear >=1960 , mcolor(black) msymbol(D))
			(rcap lower upper startyear3 if measure == "wdi" & startyear >=1960 , lcolor(gs10)) 	
			(sc beta startyear3 if measure == "wdi" & startyear >=1960 , mcolor(plb1) msymbol(S))
			(rcap lower upper startyear4 if measure == "bm" & startyear >=1960 , lcolor(gs10)) 	
			(sc beta startyear4 if measure == "bm" & startyear >=1960 , mcolor(green) msymbol(F))
            (rcap lower upper startyear5 if measure == "dmsp" & startyear >=1960 , lcolor(gs10)) 
			(sc beta startyear5 if measure == "dmsp" & startyear >=1960 , mcolor(purple) msymbol(G))
			, 	
			plotregion(style(none) lcolor(none)) yline(0,lcolor(black) lwidth(medium)) xlabel(1960(5)2020, angle(45)) 
				graphregion(fcol(white) lcol(white)) 
				title("{&beta}-coefficient of unconditional convergence", size(medlarge))
				subtitle("Regressing real per capita GDP growth to present day""on the log of initial per capita GDP", size(small))
				ytitle("{&beta}", orientation(horizontal) size(large)) 
				xtitle("Initial Year") xsize(4) ysize(6)
				note("Each point represents the coefficient from a separate,"
				"bivariate regression. The dependent variable is the annual"
				"real per capita growth rate from the year listed until the"
				"most recent data round. The independent variable is the log"
				"of real per capital GDP in the base year. Lights GDP measures"
				"(Black Marble and DMSP) were derived by using the predicted"
				"values of a regression of log(GDP PPP from WDI) on"
				"log(Lights/Area) with country and year fixed effects. Sample"
				"excludes oil-rich countries (i.e. 'Export Earnings: Fuel' in"
				"IMF DOTS), and countries with populations under 1 million.")
				legend(order(	2 "Maddison" 
								4 "PWT"
								6 "WDI"
								8 "Black Marble"
                                10 "DMSP") pos(8) ring(0) col(1)
								region(lcolor(none) fcolor(none)));
		#delimit cr
		gr_edit .style.editstyle declared_ysize(6) editcopy
		gr_edit .style.editstyle declared_xsize(4) editcopy
		graph export "$overleaf/beta_by_series.pdf", replace
		graph export "$overleaf/beta_by_series.png", replace
