/* This does time series prediction on the NTL/GDP data 
First, loop through each year:
for each year
for 2 regression types (one with country FE and one without country FE)
fit regression on the 3 years prior
predict the values in the 1 year after
get the residual of this out-of-sample prediction into a table
plot the residual values vs. time (to see any pattern)
 */

use "$input/iso3c_year_viirs_new.dta", clear



// create table to store output
clear
set obs 1
gen year = "N/A"
gen fe = "N/A"
gen x_var = "N/A"
gen RMSE = 99999999
gen RMSE_exp = 99999999
tempfile base
save `base'

foreach year of numlist 2014/2020 {
foreach fe in "cat_iso3c cat_year" "cat_year" {
foreach x_var in "ln_del_sum_pix" "ln_del_sum_pix_area" "ln_sum_pix" "ln_sum_pix_area" {

use "$input/iso3c_year_viirs_new.dta", clear

/* keep the data for model training */
gen diff_yr_start = year - `year'
keep if diff_yr_start >= -2 & diff_yr_start <= 1
assert !mi(diff_yr_start)

/* fit the regression on training sample */
reghdfe ln_WDI_ppp ln_del_sum_pix if diff_yr_start >= -2 & diff_yr_start < 1, absorb(`fe') resid
assert mi(_reghdfe_resid) if diff_yr_start == 1

/* predict on out of sample */
keep if diff_yr_start == 1
predict yhat, xb

/* get out of sample prediction RMSE */
gen SE = (yhat - ln_WDI_ppp)^2
gen N_obs = _N

// store coefficients into my table
clear
set obs 1
gen income_group = "`income_group'"
gen light_var = "`light_var'"
gen LHS_var = "`LHS_var'"
gen fixed_effects = "`fixed_effects'"
gen point = `b'
gen ul = `ul'
gen ll = `ll'
gen yr_start = `year'
gen yr_end = `year' + 1 
gen WR2 = `y'
append using `base'
save `base', replace

restore



}
}
