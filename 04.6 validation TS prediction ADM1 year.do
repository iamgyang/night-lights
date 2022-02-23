/* This does time series prediction on the NTL/GDP data at an ADM1 year level
First, loop through each year:
for each year
for 2 regression types (one with country FE and one without country FE)
fit regression on the 3 years prior
predict the values in the 1 year after
get the residual of this out-of-sample prediction into a table
plot the residual values vs. time (to see any pattern)
 */

// get the maximum year minus 1 (that's when our for loop will end)
use "$input/adm1_oecd_ntl_grp.dta", clear
sum year, meanonly
local end_yr = r(max) - 1 
local start_yr = r(min) + 2

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

foreach year of numlist `start_yr'/`end_yr' {
foreach fe in `"cat_region cat_year"' `"cat_iso3c cat_year"' `"cat_year"'  `"nothing"' {
foreach x_var in "ln_del_sum_pix" "ln_del_sum_pix_area" "ln_sum_pix" "ln_sum_pix_area" {

// 2019 cat_region cat_year ln_del_sum_pix
// local fe "cat_region cat_year"
// local year 2019
// local x_var "ln_del_sum_pix"

di "!!!!!!!!! `year' `fe' `x_var'"
use "$input/adm1_oecd_ntl_grp.dta", clear

/* keep the data for model training */
gen diff_yr_start = year - `year'
keep if diff_yr_start >= -2 & diff_yr_start <= 1
assert !mi(diff_yr_start)

/* fit the regression on training sample */
if "`fe'" != "nothing" {
    reghdfe ln_GRP `x_var' if diff_yr_start >= -2 & diff_yr_start < 1, absorb(`fe') resid
    assert mi(_reghdfe_resid) if diff_yr_start == 1
}
else if "`fe" == "nothing" {
    reg ln_GRP `x_var' if diff_yr_start >= -2 & diff_yr_start < 1, resid
    assert mi(_resid) if diff_yr_start == 1
}

/* predict on out of sample */
keep if diff_yr_start == 1
predict yhat, xb

/* get out of sample prediction RMSE */
preserve
gen SE = (yhat - ln_GRP)^2
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
gen SE = (exp(yhat) - GRP)^2
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




