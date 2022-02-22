/*
           _           _                             
          (_)         | |                            
 __      ___ _ __   __| | _____      __              
 \ \ /\ / / | '_ \ / _` |/ _ \ \ /\ / /              
  \ V  V /| | | | | (_| | (_) \ V  V /               
   \_/\_/ |_|_| |_|\__,_|\___/ \_/\_/                
                  __  __ _      _            _       
                 / _|/ _(_)    (_)          | |      
   ___ ___   ___| |_| |_ _  ___ _  ___ _ __ | |_ ___ 
  / __/ _ \ / _ \  _|  _| |/ __| |/ _ \ '_ \| __/ __|
 | (_| (_) |  __/ | | | | | (__| |  __/ | | | |_\__ \
  \___\___/ \___|_| |_| |_|\___|_|\___|_| |_|\__|___/
*/

clear
set obs 1
gen point = 99999999
gen ul = 99999999
gen ll = 99999999
gen yr_start = 99999999
gen yr_end = 99999999
tempfile base
save `base'

foreach fix_samp in varied_samp fixed_samp {
foreach light in viirs dmsp {
foreach fix_yr in start end vary {
foreach gdp_var in ln_WDI ln_WDI_ppp_pc {
foreach sample in fixed variable {
	// gets me the countries I need to restrict for the fixed sample coefficients.
	if "`fix_samp'" == "fixed_samp" {
		filelist , dir("$input") pattern(country_list_`light'_`fix_yr'_`gdp_var'_`sample'_*)
		gen fullname = dirname + "/" + filename
		levelsof fullname, local(fullname)
		clear
		gen iso3c = ""
		foreach i in `fullname' {
			append using "`i'"
		}
		gduplicates drop
		if "`fix_yr'" == "start" {
			loc u yr_end
		}
		else if "`fix_yr'" == "end" {
			loc u yr_start
		}

		keep iso3c `u'
		bys iso3c: gen n = _N
		summ n
		keep if n == `r(max)'
		keep iso3c
		gduplicates drop

		gen keep = 1
		save "$input/reduced_country_list_`light'_`fix_yr'_`gdp_var'_`sample'.dta", replace
	}
	
foreach n of numlist 1/22 {
	use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear

	if ("`fix_yr'" == "start") {
		if "`light'" == "viirs" {
			local yr_start = 2012
			local yr_end   = min(`yr_start' + `n', 2020)
		}
		else if "`light'" == "dmsp" {
			local yr_start = 1992
			local yr_end   = min(`yr_start' + `n', 2013)
		}
	}
	else if ("`fix_yr'" == "end") {
		if "`light'" == "viirs" {
			local yr_end = 2020
			local yr_start   = max(`yr_end' - `n', 2012)
		}
		else if "`light'" == "dmsp" {
			local yr_end = 2013
			local yr_start   = max(`yr_end' - `n', 1992)
		}
	}
	else if ("`fix_yr'" == "vary") {
		if "`light'" == "viirs" {
			local yr_start = min(2011 + `n', 2019)
			local yr_end   = min(`yr_start' + 1, 2020)
		}
		else if "`light'" == "dmsp" {
			local yr_start = min(1991 + `n', 2012)
			local yr_end   = min(`yr_start' + 1, 2013)
		}
	}

	assert `yr_start' < `yr_end'
	assert 2021 > `yr_end'
	assert 1991 < `yr_start'

	if ("`light'" == "viirs") {
		loc light_var ln_del_sum_pix_area
	}
	else if ("`light'" == "dmsp") {
		loc light_var ln_sum_light_dmsp_div_area
	}

	// long difference regression:
	keep if inlist(year, `yr_start', `yr_end')
	keep `gdp_var' `light_var' year iso3c
	sort iso3c year

	// long difference variables:
	foreach i in `gdp_var' `light_var' {
		bys iso3c: gen lg_`i' = `i' - `i'[_n-1]
		drop `i'
	}

	// filter for countries where we have data
	naomit
	
	// IF we want to fix a sample, then merge with the dataset where we show 
	// which countries we want to look at
	if ("`fix_samp'" == "fixed_samp") {
		mmerge iso3c using "$input/reduced_country_list_`light'_`fix_yr'_`gdp_var'_`sample'.dta"
		keep if keep == 1
		pause "`light' `fix_yr' `gdp_var' `sample' `n'"
	}
	
	// for the first round of varied samples, save the country list
	if ("`fix_samp'" == "varied_samp") {
		gen yr_start = `yr_start'
		gen yr_end = `yr_end'
		save "$input/country_list_`light'_`fix_yr'_`gdp_var'_`sample'_`n'.dta", replace
	}
	
	// pause "`light' `fix_yr' `gdp_var' `sample' `n'"

	// do regression
	reg lg_`gdp_var' lg_`light_var', vce(hc3)

	// get the upper and lower confidence intervals and the point estimate
	matrix list r(table)
	matrix test = r(table)
	foreach i in b ll ul {
		matrix `i' = test["`i'", "lg_`light_var'"]
		loc `i' = `i'[1,1]
	}

	clear
	set obs 1
	gen point = `b'
	gen ul = `ul'
	gen ll = `ll'
	gen yr_start = `yr_start'
	gen yr_end = `yr_end'
	gen gdp_var = "`gdp_var'"
	gen light = "`light'"
	gen fix_yr = "`fix_yr'"
	gen fix_samp = "`fix_samp'"
	append using `base'
	save `base', replace
}
}
}
}
}
}

clear
use  `base'
drop if point >9999
sort gdp_var
gduplicates drop
save "$input/window_reg_results.dta", replace

/*
           _           _                
          (_)         | |               
 __      ___ _ __   __| | _____      __ 
 \ \ /\ / / | '_ \ / _` |/ _ \ \ /\ / / 
  \ V  V /| | | | | (_| | (_) \ V  V /  
   \_/\_/ |_|_| |_|\__,_|\___/ \_/\_/   
                       | |              
   __ _ _ __ __ _ _ __ | |__  ___       
  / _` | '__/ _` | '_ \| '_ \/ __|      
 | (_| | | | (_| | |_) | | | \__ \      
  \__, |_|  \__,_| .__/|_| |_|___/      
   __/ |         | |                    
  |___/          |_|                    

*/

// Graph
foreach fix_samp in varied_samp fixed_samp {
foreach gdp_var in ln_WDI ln_WDI_ppp_pc {
foreach fix_yr in start end vary {
use "$input/window_reg_results.dta", replace

// Filter Dataset:
keep if gdp_var == "`gdp_var'"
keep if fix_yr == "`fix_yr'"
keep if fix_samp == "`fix_samp'"
if ("`fix_yr'" == "start") {
	keep if (light == "dmsp" & yr_start == 1992) | (light == "viirs" & yr_start == 2012)	
	loc xvar yr_end
}
else if ("`fix_yr'" == "end") {
	keep if (light == "dmsp" & yr_end == 2013) | (light == "viirs" & yr_end == 2020)	
	loc xvar yr_start
}
else if ("`fix_yr'" == "vary") {
	loc xvar yr_start
}
drop if yr_start == yr_end
gduplicates drop
sort `xvar'

// Title Labels
if ("`fix_yr'" == "start" | "`fix_yr'" == "end") {
// 	loc lab1 "Window fixed at `fix_yr' of period"
}
else if ("`fix_yr'" == "vary") {
// 	loc lab1 "1-yr window"
// 	loc ytitle `""Coefficient of" "Log GDP (end) - Log GDP (start)" "vs." "Log Lights (end) - Log Lights (start)""'
}

if ("`gdp_var'" == "ln_WDI_ppp_pc") {
// 	loc lab2 "using per capita GDP"
}
else {
// 	loc lab2 "using absolute GDP"
}

# delimit ;
twoway (line point `xvar' if light == "dmsp") 
(line point `xvar' if light == "viirs", lpattern(dash)) 
(scatter point `xvar') (rcap ul ll `xvar', lcolor(%50) msize(4-pt)), 
ytitle("`ytitle'") ytitle(, 
orientation(horizontal)) xtitle("") 
title("`lab1'" "`lab2'") 
legend(on order(1 "DMSP" 2 "VIIRS") 
margin(zero) nobox region(fcolor(none) margin(zero) lcolor(none)) 
position(12))
xsize(10) ysize(5)
;
# delimit cr

gr export "$overleaf/graph_`gdp_var'_`fix_yr'_`fix_samp'.pdf", replace
}
}
}

//                                 (_) |        
//   ___ ___  _ __   ___ __ ___   ___| |_ _   _ 
//  / __/ _ \| '_ \ / __/ _` \ \ / / | __| | | |
// | (_| (_) | | | | (_| (_| |\ V /| | |_| |_| |
//  \___\___/|_| |_|\___\__,_| \_/ |_|\__|\__, |
//                                         __/ |
//                                        |___/ 

use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear
keep if year == 2013 | year == 2020
keep iso3c year cat_income2012 ln_WDI_ppp_pc ln_WDI ln_del_sum_pix_area
naomit
sort iso3c year

// logged variables
loc gdp_var ln_WDI ln_WDI_ppp_pc
loc light_var ln_del_sum_pix_area
foreach i in `gdp_var' `light_var' {
	bys iso3c: gen lg_`i' = `i'[_n+1] - `i'
	loc lab: variable label `i'
	label variable lg_`i' "Long Difference `lab'"
}
naomit

gen income = ""
replace income = "LIC" if cat_income2012 == 1
replace income = "LMIC" if cat_income2012 == 2
replace income = "UMIC" if cat_income2012 == 3
replace income = "HIC" if cat_income2012 == 4

save "$input/long_diff_concavity_dataset.dta", replace

// regress long diff log GDP ~ long diff log lights + log lights 2012 : long diff log lights
est clear
eststo: reg lg_ln_WDI lg_ln_del_sum_pix_area c.lg_ln_del_sum_pix_area#c.ln_del_sum_pix_area, vce(hc3)
eststo: reg lg_ln_WDI lg_ln_del_sum_pix_area i.cat_income2012#c.ln_del_sum_pix_area, vce(hc3)
esttab using "$overleaf/concavity.tex", replace f  ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
label booktabs nobaselevels collabels(none) ///
sfmt(3)

/*
  _                         _ _  __  __ 
 | |                       | (_)/ _|/ _|
 | | ___  _ __   __ _    __| |_| |_| |_ 
 | |/ _ \| '_ \ / _` |  / _` | |  _|  _|
 | | (_) | | | | (_| | | (_| | | | | |  
 |_|\___/|_| |_|\__, |  \__,_|_|_| |_|  
                 __/ | | |              
   __ _ _ __ __ |___/_ | |__            
  / _` | '__/ _` | '_ \| '_ \           
 | (_| | | | (_| | |_) | | | |          
  \__, |_|  \__,_| .__/|_| |_|          
   __/ |         | |                    
  |___/          |_|                    
*/


// Full Long Difference Graph
use "$input/long_diff_concavity_dataset.dta", clear
# delimit ;
twoway  

(lpoly lg_ln_WDI lg_ln_del_sum_pix_area if income == "LIC", 
lcolor(cranberry))

(lpoly lg_ln_WDI lg_ln_del_sum_pix_area if income == "LMIC", 
lcolor(blue))

(lpoly lg_ln_WDI lg_ln_del_sum_pix_area if income == "UMIC", 
lcolor(green))

(lpoly lg_ln_WDI lg_ln_del_sum_pix_area if income == "HIC", 
lcolor(purple))


(scatter lg_ln_WDI lg_ln_del_sum_pix_area if 
income == "LIC", mcolor(cranberry) msize(tiny) 
mlabel(iso3c) mlabsize(vsmall))

(scatter lg_ln_WDI lg_ln_del_sum_pix_area if 
income == "LMIC", mcolor(blue) msize(tiny) 
mlabel(iso3c) mlabsize(vsmall))

(scatter lg_ln_WDI lg_ln_del_sum_pix_area if 
income == "UMIC", mcolor(green) msize(tiny) 
mlabel(iso3c) mlabsize(vsmall))

(scatter lg_ln_WDI lg_ln_del_sum_pix_area if 
income == "HIC", mcolor(purple) msize(tiny) 
mlabel(iso3c) mlabsize(vsmall))

, 
ytitle("ln(GDP20) − ln(GDP13)") 
ytitle(, orientation(horizontal)) 
xtitle("ln(lights20) − ln(lights13)") 
subtitle("`income_group'")
 
legend(on order(
1 "LIC" 
2 "LMIC"
3 "UMIC"
4 "HIC"
) 
margin(zero) nobox region(fcolor(none) margin(zero) lcolor(none)) 
position(12))
xsize(70) ysize(40)
scale(0.7)
;

gr export "$overleaf/graph_long_difference_income_composite.pdf", 
as(png) width(3000) height(1714) replace
;
# delimit cr

// Subsetted Long Difference Graph
foreach income_group in LIC LMIC UMIC HIC {

# delimit ;
twoway  
(lpoly lg_ln_WDI lg_ln_del_sum_pix_area if income == "`income_group'", 
lcolor(cranberry))
(scatter lg_ln_WDI lg_ln_del_sum_pix_area if 
income == "`income_group'", mcolor(%50) msize(tiny) 
mlabel(iso3c) mlabsize(vsmall))
, 
ytitle("ln(GDP20) − ln(GDP13)") 
ytitle(, orientation(horizontal)) 
xtitle("ln(lights20) − ln(lights13)") 
subtitle("`income_group'") legend(off)
xsize(70) ysize(40)
scale(0.7)
;

gr export "$overleaf/graph_long_difference_income_`income_group'.pdf", 
as(png) width(3000) height(1714) replace
;
# delimit cr
}














