/* 
get NTL data at country level
for each year, fit regression at country level (using WDI LCU)
impute the GDP at a subnational level
for the OECD countries, compare this imputed subnational GDP to actual subnational GDP (just do a graph)
for the OECD countries, compare this imputed subnational GDP to actual subnational GDP --- compare based on rural / urban divide
 */

pause on

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
foreach fe in `"cat_iso3c cat_year"' `"cat_year"' `"nothing"' {
foreach x_var in "ln_del_sum_pix" "ln_del_sum_pix_area" "ln_sum_pix" "ln_sum_pix_area" {
local fe "nothing"
local year 2018
local x_var "ln_del_sum_pix_area"
di "!!!!!!!!! `year' `fe' `x_var'"
use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear

/* keep the data for model training */
gen diff_yr_start = year - `year'
keep if diff_yr_start >= -2 & diff_yr_start <= 1
assert !mi(diff_yr_start)

/* fit the regression on training sample */
if "`fe'" != "nothing" {
    reghdfe ln_WDI `x_var' if diff_yr_start >= -2 & diff_yr_start < 1, absorb(`fe') resid
    assert mi(_reghdfe_resid) if diff_yr_start == 1
}
else if "`fe" == "nothing" {
    reg ln_WDI `x_var' if diff_yr_start >= -2 & diff_yr_start < 1, resid
    assert mi(_resid) if diff_yr_start == 1
}

/* predict on out of sample */
use "$input/adm1_oecd_ntl_grp.dta", clear
gen diff_yr_start = year - `year'
keep if diff_yr_start >= -2 & diff_yr_start <= 1
keep if diff_yr_start == 1
di "`fe'"
predict yhat, xb
pause

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




