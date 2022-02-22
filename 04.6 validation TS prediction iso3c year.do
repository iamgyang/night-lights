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

foreach year of numlist 2014/2019 {
foreach fe in `"cat_iso3c cat_year"' `"cat_year"' {
foreach x_var in "ln_del_sum_pix" "ln_del_sum_pix_area" "ln_sum_pix" "ln_sum_pix_area" {
local fe "cat_year cat_iso3c"
local year 2014
local x_var "ln_del_sum_pix_area"
di "!!!!!!!!! `year' `fe' `x_var'"
use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear

/* keep the data for model training */
gen diff_yr_start = year - `year'
keep if diff_yr_start >= -2 & diff_yr_start <= 1
assert !mi(diff_yr_start)

/* fit the regression on training sample */
reghdfe ln_WDI_ppp `x_var' if diff_yr_start >= -2 & diff_yr_start < 1, absorb(`fe') resid
assert mi(_reghdfe_resid) if diff_yr_start == 1

/* predict on out of sample */
keep if diff_yr_start == 1
predict yhat, xb

/* get out of sample prediction RMSE */
preserve
gen SE = (yhat - ln_WDI_ppp)^2
gegen sum_SE = sum(SE)
drop if mi(SE)
gen N_obs = _N
keep sum_SE N_obs
gduplicates drop
gen RMSE = sum_SE / N_obs
gen n = _N
assert n == 1
su RMSE, meanonly 
local RMSE = r(max)
di "`RMSE'"
restore

/* get out of sample prediction RMSE for non-logged values */
preserve
gen SE = (exp(yhat) - WDI_ppp)^2
gegen sum_SE = sum(SE)
drop if mi(SE)
gen N_obs = _N
keep sum_SE N_obs
gduplicates drop
gen RMSE = sum_SE / N_obs
gen n = _N
assert n == 1
su RMSE, meanonly 
local RMSE_exp = r(max)
di "`RMSE_exp'"
restore

// store coefficients into my table
clear
set obs 1
gen year = "`year'"
gen fe = "`fe'"
gen x_var = "`x_var'"
gen RMSE = `RMSE'
gen RMSE_exp = `RMSE_exp'
append using `base'
save `base', replace
}
}
}

clear
use `base'
drop if year == "N/A"




