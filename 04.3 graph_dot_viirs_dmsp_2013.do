// TEST: ---------------------------------------------------------------

use "$input/sample_iso3c_year_pop_den__allvars2.dta", clear

// delete pairwise missing variables
loc exp_var ln_WDI_ppp_pc del_sum_area poptotal
keep iso3c year ln_sum_light_dmsp_div_area ln_del_sum_pix_area `exp_var'
naomit

// regress DMSP~VIIRS
eststo clear
eststo: reg ln_sum_light_dmsp_div_area ln_del_sum_pix_area, vce(hc3)
predict yhat, xb
gen resid = -abs(ln_sum_light_dmsp_div_area - yhat)
sort resid
gen n = _n

// label the top 40 points
gen lab_iso3c = iso3c if n<40

// graph
set graphics off
twoway (scatter ln_sum_light_dmsp_div_area ln_del_sum_pix_area, msize(small) msymbol(circle) mlabel(lab_iso3c) mlabcolor(%70))
set graphics on

// export to overleaf
gr export "$overleaf/dot_dmsp_viirs_2013.pdf", replace

create_logvars `"`exp_var'"'

// analysis of WHY residual
replace resid = (ln_sum_light_dmsp_div_area - yhat)
label variable resid "Residuals"
eststo: reg resid ln_WDI_ppp_pc ln_del_sum_area ln_poptotal, vce(hc3)
eststo: reg resid ln_WDI_ppp_pc  , vce(hc3)
eststo: reg resid ln_del_sum_area  , vce(hc3)
eststo: reg resid ln_poptotal  , vce(hc3)

esttab using "$overleaf/dmsp_viirs_2013.tex", replace f  ///
	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
	label booktabs nobaselevels ///
	sfmt(3) ar2





















