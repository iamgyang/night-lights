local start_yr = 2014
local end_yr = 2020
est clear
set graphics off

foreach light_var in ln_sum_pix_bm_dec_area  ln_del_sum_pix_area {

use "$input/iso3c_year_aggregation.dta", clear
keep if year == `start_yr' | year == `end_yr' // this is for BM (which we only have up to 2014)
keep iso3c year cat_income2012 ln_WDI_ppp_pc ln_WDI `light_var'
naomit
sort iso3c year

// logged variables
loc gdp_var ln_WDI ln_WDI_ppp_pc
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

// drop outliers
drop if iso3c == "GNQ" | iso3c == "MAC"

save "$input/long_diff_concavity_dataset.dta", replace


// regress long diff log GDP ~ long diff log lights + log lights 2012 : long diff log lights
reg lg_ln_WDI lg_`light_var' c.lg_`light_var'#c.`light_var', vce(hc3)
eststo reg_`light_var'1
reg lg_ln_WDI lg_`light_var' i.cat_income2012#c.`light_var', vce(hc3)
eststo reg_`light_var'2

// Full Long Difference Graph
use "$input/long_diff_concavity_dataset.dta", clear
# delimit ;
twoway  

(lfit lg_ln_WDI lg_`light_var' if income == "LIC", 
lcolor(cranberry) )

(lfit lg_ln_WDI lg_`light_var' if income == "HIC", 
lcolor(purple) )


(scatter lg_ln_WDI lg_`light_var' if 
income == "LIC", mcolor(cranberry) msize(tiny) 
mlabel(iso3c) mlabsize(vsmall))

(scatter lg_ln_WDI lg_`light_var' if 
income == "HIC", mcolor(purple) msize(tiny) 
mlabel(iso3c) mlabsize(vsmall))

, 
ytitle("ln(GDP20) − ln(GDP13)") 
ytitle(, orientation(horizontal)) 
xtitle("ln(lights20) − ln(lights13)") 
subtitle("`income_group'")
 
legend(on order(
1 "LIC" 
2 "HIC"
) 
margin(zero) nobox region(fcolor(none) margin(zero) lcolor(none)) 
position(12))
xsize(70) ysize(40)
scale(0.7)
;

gr export "$overleaf/graph_long_difference_income_composite_`light_var'.png", 
as(png) width(3000) height(1714) replace
;
# delimit cr

// Subsetted Long Difference Graph
foreach income_group in LIC LMIC UMIC HIC {

# delimit ;
twoway  
(lfit lg_ln_WDI lg_`light_var' if income == "`income_group'", 
lcolor(cranberry) )
(scatter lg_ln_WDI lg_`light_var' if 
income == "`income_group'", mcolor(%50) msize(tiny) 
mlabel(iso3c) mlabsize(vsmall))
, 
ytitle("ln(GDP `end_yr') − ln(GDP `start_yr')") 
ytitle(, orientation(horizontal)) 
xtitle("ln(lights `end_yr') − ln(lights `start_yr')") 
subtitle("`income_group'") legend(off)
xsize(70) ysize(40)
scale(0.7)
;

gr export "$overleaf/graph_long_difference_income_`income_group'_`light_var'.png", 
as(png) width(3000) height(1714) replace
;
# delimit cr
}

}

esttab reg_ln_del_sum_pix_area1 reg_ln_del_sum_pix_area2 reg_ln_sum_pix_bm_dec_area1 reg_ln_sum_pix_bm_dec_area2 using "$overleaf/concavity.tex", replace f  ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
label booktabs nobaselevels collabels(none) ///
sfmt(3)