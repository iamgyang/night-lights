/*
One hypothesis is that the henderson regressions don't really make sense because
night lights should work in places where there is high density of PEOPLE. So, in
these data, we've filtered the night lights and polygon areas to be above a
certain level of population density (defined as population from year 2015
divided by polygon area). The 'level' we've used as a cutoff is the Xth
percentile for a certain country at a certain year. (e.g. if at the 95th
percentile, the USA has 10 people per polygon area, then we looked only at night
light values that had population densities greater than 10). This file imports
that data and rudimentarily cleans it, prepping it to be merged with other
country-year datasets.

NOTE: this relies on running the R file which creates the percentile population
densities.
*/
foreach i of numlist 79(5)99{
	use "$input/ntl_iso3c_yr_cut_den_`i'.dta", clear
	drop pop_den
	foreach var in del_sum_pix del_sum_area sum_pix sum_area {
		rename `var' `var'_`i'
	}
	tempfile tfile_`i'
	save `tfile_`i''
}
use `tfile_79'
foreach i of numlist 84(5)99{
	di `i'
	mmerge iso3c year using `tfile_`i''
	drop _merge
}
save "$input/clean_high_density_ntl.dta", replace












