/* Pseudo Randomization Inference */

/* Get a list of countries where we have all data in all years for 2012-2020
GDP. Randomly pair countries together. For each country, replace that country's
NTL data with the other country's NTL data. Run the HWS regressions here as
well, and compare the regressions. */

/* Global log levels regression is highly significant */
    use "$input/iso3c_year_aggregation.dta", clear
    reghdfe ln_WDI ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
    eststo country_wdi3
    estadd local NC `e(N_clust)'
    local y = round(`e(r2_a_within)', .001)
    estadd local WR2 `y'	
    estadd local AGG "Country"
    estadd local ADM1_FE ""
    estadd local Year_FE "X"
    estadd local Country_FE "X"

// does the result hold under bootstrap? Yes!
/* Note: this bootstrap samples entire COUNTRIES 50 times. */
// bootstrap, rep(50) cluster(cat_iso3c) size(50): ///
//     reghdfe ln_WDI ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)

/* does the result hold if I randomize which countries get which lights? No!
(which is a good thing) */
    use "$input/iso3c_year_aggregation.dta", clear
    keep ln_WDI ln_del_sum_pix_area iso3c year
    naomit
	fillin iso3c year
	drop _fillin
	sort iso3c year
	levelsof year, local(years)
    local num_years : list sizeof local(years)

    /* randomly sort the countries I have */
    preserve
	keep iso3c
    gduplicates drop
    gen sortorder = runiform()
	tempfile isos
	save `isos'
	restore
    
    /* order the data table's countries randomly, and create a variable that is
    the next country's dataset at the SAME year. */
	mmerge iso3c using `isos'
	assert _merge == 3
	drop _merge
	sort sortorder year
	quietly capture drop rand_ln_del_sum_pix_area 
	describe
	local num_row_check_before = r(N)
	gen rand_ln_del_sum_pix_area = ///
		ln_del_sum_pix_area[1+mod(_n+`num_years'-1, `num_row_check_before')]
	gen rand_year = ///
		year[1+mod(_n+`num_years'-1, `num_row_check_before')]
	assert rand_year == year
	drop rand_year
	create_categ(iso3c year)
	
	// our original regression
	reghdfe ln_WDI ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
    eststo country_wdi3
    estadd local NC `e(N_clust)'
    local y = round(`e(r2_a_within)', .001)
    estadd local WR2 `y'	
    estadd local AGG "Country"
    estadd local ADM1_FE ""
    estadd local Year_FE "X"
    estadd local Country_FE "X"
	
	// new randomized regression
	reghdfe ln_WDI rand_ln_del_sum_pix_area, absorb(cat_iso3c cat_year) vce(cluster cat_iso3c)
    eststo country_wdi3
    estadd local NC `e(N_clust)'
    local y = round(`e(r2_a_within)', .001)
    estadd local WR2 `y'	
    estadd local AGG "Country"
    estadd local ADM1_FE ""
    estadd local Year_FE "X"
    estadd local Country_FE "X"
	
    /* okay, so original regression holds muster */
.