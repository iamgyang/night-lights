// create table to store output
clear
set obs 1
gen income_group = "N/A"
gen light_var = "N/A"
gen ul = 99999999
gen point = 99999999
gen ll = 99999999
gen yr_start = 99999999
gen yr_end = 99999999
gen fixed_effects = "N/A"
gen WR2 = 999999999
tempfile base
save `base'

/*
reg taxes_exc_soc imports exports credit rgdp_lcu elec
Fit GDP~4 variables for all years.
For each year, regress log(GDP)~log(NTL) and plot the coefficients.
For each year, regress log(GDP_hat)~log(NTL) and plot the coefficients.
Do this for both DMSP and VIIRS, global, OECD, etc.
*/

foreach income_group in "Global" "OECD" "Not OECD" {
foreach light_var in "VIIRS" "DMSP" {
foreach fixed_effects in "cat_year cat_iso3c" {

use "$input/clean_synthetic_reg_prior.dta", replace
br

// define which countries we keep
if "`income_group'" == "OECD" {
keep_oecd, iso_var(iso3c)
} 
else if "`income_group'" == "Not OECD" {
drop_oecd, iso_var(iso3c)
}

keep ln_rgdp_lcu ln_del_sum_pix_area year ln_sum_light_dmsp_div_area cat_iso3c cat_year

// define the years we do the regression on
if "`light_var'" == "VIIRS" {
	loc years "2013/2019"
	loc years_group `""2013" "2014" "2015" "2016" "2017" "2018" "2019""'
	rename ln_del_sum_pix_area RHS_var
}
else if "`light_var'" == "DMSP" {
	loc years "1992/2012"
	loc years_group `""1992" "1993" "1994" "1995" "1996" "1997" "1998" "1999" "2000" "2001" "2002" "2003" "2004" "2005" "2006" "2007" "2008" "2009" "2010" "2011" "2012""'
	rename ln_sum_light_dmsp_div_area RHS_var
}

// define the LHS var:
rename ln_rgdp_lcu LHS_var

// regressions
est clear
foreach year of numlist `years' {
    
	eststo: reghdfe LHS_var RHS_var if (year == `year' | year == `year' + 1), absorb(`fixed_effects') vce(cluster cat_iso3c)
		estadd local NC `e(N_clust)'
		local y= round(`e(r2_a_within)', .001)
		estadd local WR2 `y'
		
	// get the upper and lower confidence intervals and the point estimate
	preserve
	
	matrix list r(table)
	matrix test = r(table)
	foreach i in b ll ul {
		matrix `i' = test["`i'", "RHS_var"]
		loc `i' = `i'[1,1]
	}
	
	// store coefficients into my table
	clear
	set obs 1
	gen income_group = "`income_group'"
	gen light_var = "`light_var'"
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

// output results into LATEX

local scalar_labels `"scalars("NC Number of Countries" "WR2 Adjusted Within R-squared")"'

esttab using "$overleaf/`income_group'_`light_var'_`fixed_effects'.tex", replace f  ///
b(3) se(3) ar2 nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
booktabs collabels(none) mgroups(`years_group', ///
pattern(1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
coeflabel(RHS_var "Log Lights/Area") ///
`scalar_labels'
}
}
}

// save table results
clear
use  `base'
drop if point >9999
sort light_var yr_start
gduplicates drop
save "$input/synthetic_gdp_results.dta", replace

foreach light_var in "DMSP" "VIIRS" {
foreach income_group in "OECD" "Not OECD" "Global" {
foreach fixed_effects in "year and country" {

use "$input/synthetic_gdp_results.dta", clear

if "`fixed_effects'" == "year and country" {
    loc FE "cat_year cat_iso3c"
}
else if "`fixed_effects'" == "year" {
    loc FE "cat_year"
}
else if "`fixed_effects'" == "country" {
    loc FE "cat_iso3c"
}
keep if fixed_effects == "`FE'"
keep if income_group == "`income_group'"
keep if light_var == "`light_var'"

// get start and end years:
summarize yr_start
local x_axis_start `r(min)'
local x_axis_end `r(max)'

// graphs
set graphics off
# delimit ;
twoway (line point yr_start, lcolor(red)) 
(scatter point yr_start) (rcap ul ll yr_start, lcolor(%50) msize(4-pt)), 
ytitle("`ytitle'") ytitle(, 
orientation(horizontal)) xtitle("") 
xsize(10) ysize(5)
xlabel(`x_axis_start'(2)`x_axis_end')
legend(off)
;
# delimit cr
gr export "$overleaf/synthetic_GDP_`light_var'_`income_group'_`fixed_effects'_fixed_effects.png", replace
set graphics on

set graphics off
# delimit ;
twoway (line WR2 yr_start, lcolor(red)) 
(scatter WR2 yr_start) , 
ytitle("`ytitle'") ytitle(, 
orientation(horizontal)) xtitle("") 
xsize(10) ysize(5)
xlabel(`x_axis_start'(2)`x_axis_end')
legend(off)
;
# delimit cr
gr export "$overleaf/synthetic_GDP_`light_var'_`income_group'_`fixed_effects'_fixed_effects_WR2.png", replace
set graphics on

}
}
}


use "$input/clean_synthetic_reg_prior.dta", clear
scatter ln_rgdp_lcu ln_del_sum_pix



