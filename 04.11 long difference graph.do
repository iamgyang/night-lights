
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

