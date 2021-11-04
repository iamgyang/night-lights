use "$input/sample_iso3c_month_allvars.dta", clear
rename pwt_rgdpna PWT
foreach i in sum_pix sum_area del_sum_pix del_sum_area {
    replace `i' = . if `i' == 0
}

// per area variables:
gen del_sum_pix_area = del_sum_pix / del_sum_area
gen sum_pix_area = sum_pix / sum_area
gen sum_pix_new_area = sum_pix_new / del_sum_area_new // CHANGE TO sum_area_new in the new iteration!!!!!!!!!!!!
gen sum_light_dmsp_div_area = sum_light_dmsp / sum_area

// label variables
label variable del_sum_area "VIIRS (cleaned) polygon area"
label variable del_sum_pix "VIIRS (cleaned) sum of pixels"
label variable sum_area "lights (raw) polygon area"
label variable sum_pix "VIIRS (raw) sum of pixels"
label variable sum_pix_area "VIIRS (raw) sum of pixels / area"
label variable del_sum_pix_area "VIIRS (cleaned) pixels / area"
label variable sum_light_dmsp_div_area "DMSP sum of pixels / area"
label variable del_sum_area "VIIRS (cleaned) polygon area"
label variable del_sum_pix "VIIRS (cleaned) sum of pixels"
// label variable Oxford "Oxford real GDP LCU"
label variable PWT "PWT real GDP PPP"
label variable WDI "WDI real GDP LCU"
label variable WDI_ppp "WDI real GDP PPP"
label variable sum_area "lights (raw) polygon area"
label variable sum_pix "VIIRS (raw) sum of pixels"
label variable sum_pix_area "VIIRS (raw) sum of pixels / area"
label variable del_sum_pix_area "VIIRS (cleaned) pixels / area"
label variable sum_light_dmsp "DMSP sum of pixels"
label variable lndn "Log DMSP pixels / area (original)"
label variable lngdpwdilocal "Log WDI real GDP LCU (original)"
label variable exp_hws_wdi "WDI real GDP LCU (original)"
label variable income "WB historical income classification"
label variable poptotal "population (UN)"
label variable sum_light_dmsp_div_area "DMSP sum of pixels / area"
label variable mean_g_ln_lights_gold "Mean Growth in DMSP sum of pixels per capita (Goldberg)"
label variable _gdppercap_constant_ppp_gold "WB real GDP PPP per capita (Goldberg)"
label variable mean_g_ln_gdp_gold "Mean Growth in Log WB real GDP PPP per capita (Goldberg)"
label variable lightpercap_gold "DMSP sum of pixels per capita (Goldberg)"
label variable ln_gdp_gold "Log real GDP PPP per capita (WB, Goldberg)"
label variable sumoflights_gold "DMSP sum of pixels (Goldberg)"

// rename + label stringency index data
rename restr* cornet*
rename *index oxcgrt*

label variable cornet_business "business restriction index (Coronanet)"
label variable cornet_health_monitor "health monitoring index (Coronanet)"
label variable cornet_health_resource "health resources index (Coronanet)"
label variable cornet_mask "masking index (Coronanet)"
label variable cornet_school "school restriction index (Coronanet)"
label variable cornet_social_dist "social distancing index (Coronanet)"
label variable oxcgrtstringency "composite stringency index (Oxford)"
label variable oxcgrtgovernmentresponse "government response index (Oxford)"
label variable oxcgrtcontainmenthealth "health containment index (Oxford)"
label variable oxcgrteconomicsupport "economic support index (Oxford)"

tempfile dataset_up_to_this_point
save `dataset_up_to_this_point'

clear
input str40 measure_vars
	"PWT"
	"WDI"
	"WDI_ppp"
	"del_sum_pix"
	"sum_pix"
	"sum_light_dmsp"
	"del_sum_pix_area"
	"sum_light_dmsp_div_area"
	"sum_pix_area"
	"sumoflights_gold"
	"del_sum_pix"
	"sum_pix"
	"del_sum_pix_area"
	"sum_pix_area"
end
levelsof measure_vars, local(measure_vars)

clear
use `dataset_up_to_this_point'

local time month
local area iso3c

if ("`area'" == "iso3c") {
	
	// creates per capita values
	foreach i in `measure_vars' {
		// if it's an area command, then don't make per capita
		if strpos("`i'", "area") {
		    continue
		}
		gen `i'_pc = `i' / poptotal
		loc lab: variable label `i'
		di "`lab'"
		label variable `i'_pc "`lab' per capita"
	}
	
	// adds per capita variables to measure vars:
	foreach l in `measure_vars' {
		// if it's an area command, then don't make per capita
		if strpos("`l'", "area") {
		    continue
		}
		local measure_vars "`measure_vars' `l'_pc"
	}

}

// log values
foreach i in `measure_vars' {
	gen ln_`i' = ln(`i')
	loc lab: variable label `i'
	di "`lab'"
	label variable ln_`i' "Log `lab'"
}    

// First differences on the logged variables
// before taking first differences, HAVE TO have all years, months, etc.
fillin iso3c year `time'
check_dup_id "iso3c year `time'"
drop _fillin

// monthly differences
foreach var of varlist ln_* {
	sort iso3c year month
    generate g_`var' = `var' - `var'[_n-1] if ///
		iso3c==iso3c[_n-1]
	loc lab: variable label `var'
	di "`lab'"
	label variable g_`var' "Diff. `lab'"
}

// annual differences
foreach var of varlist ln_* {
	sort iso3c month year
    generate g_an_`var' = `var' - `var'[_n-1] if ///
		iso3c==iso3c[_n-1] & (year - 1) == (year[_n-1])
	loc lab: variable label `var'
	di "`lab'"
	label variable g_an_`var' "Diff. annual `lab'"
}

// encode categorical variables (numeric --> categorical)
foreach i in year {
	gen str_`i' = string(`i')
	encode str_`i', gen(cat_`i')
	drop str_`i'
}

// encode categorical variables (character --> categorical)
foreach i in wbdqcat iso3c {
    encode `i', gen(cat_`i')
}

// after march covid dummy:
gen after_march = 1 if month >= 3
replace after_march = 0 if month < 3

// income categorical variable
label define income 1 "LIC" 2 "LMIC" 3 "UMIC" 4 "HIC"
encode income, generate(cat_income) label(income) 

// WB data quality index
// label define wbdqcat_3 1 "bad" 2 "ok" 3 "good"
// encode wbdqcat_3, generate(cat_wbdqcat_3) label(wbdqcat_3) 

// month has to be ordered
gen str_month = string(month)
label define str_month 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10" 11 "11" 12 "12"
encode str_month, generate(cat_month) label(str_month) 
drop str_month

// get BASE year for *annual* growth regressions:
foreach i in PWT WDI_ppp {
	foreach year_base in 1992 2012 {
		gen base_ln_`i'_pc_`year_base' = ln_`i'_pc if year == `year_base'
		bysort iso3c: egen ln_`i'_pc_`year_base' = max(base_ln_`i'_pc_`year_base')
		drop base_ln_`i'_pc_`year_base'
		label variable ln_`i'_pc_`year_base' "Log `i' real GDP PPP per capita, `year_base'"
	}
}

// create an income variable that is based on the FIRST income present
foreach year_base in 1992 2012 {
	sort cat_iso3c year
	gen cat_income`year_base' = cat_income if year == `year_base'
	bysort cat_iso3c:  fillmissing cat_income`year_base', with(mean)
	capture quietly label define income 1 "LIC" 2 "LMIC" 3 "UMIC" 4 "HIC"
	label value cat_income`year_base' income
	label variable cat_income`year_base' "WB income group, `year_base'"
}

// Fill in missing world bank quality index years with the average of the WB quality index:
// bysort cat_iso3c:  fillmissing cat_wbdqcat_3, with(mean)
// gen check = mod(cat_wbdqcat_3, 1)
// assert check == 0 | check == .
// drop check

save "$input/month_iso3c_cleaned.dta", replace

// adjusted this 
use "$input/month_iso3c_cleaned.dta", clear

rename *del_* *XXX*

// swapped cleaned and uncleaned VIIRS versions:
rename sum_pix del_sum_pix
rename sum_area del_sum_area
rename sum_pix_new del_sum_pix_new
rename sum_pix_area del_sum_pix_area
rename sum_pix_pc del_sum_pix_pc
rename ln_sum_pix ln_del_sum_pix
rename ln_sum_pix_area ln_del_sum_pix_area
rename ln_sum_pix_pc ln_del_sum_pix_pc
rename g_ln_sum_pix g_ln_del_sum_pix
rename g_ln_sum_pix_area g_ln_del_sum_pix_area
rename g_ln_sum_pix_pc g_ln_del_sum_pix_pc
rename g_an_ln_sum_pix g_an_ln_del_sum_pix
rename g_an_ln_sum_pix_area g_an_ln_del_sum_pix_area
rename g_an_ln_sum_pix_pc g_an_ln_del_sum_pix_pc

rename *XXX* **
assert del_sum_pix >= sum_pix

save "$input/month_iso3c_cleaned.dta", replace

exit 

// EVENT STUDY START ========================================================

use "$input/month_iso3c_cleaned.dta", clear

mmerge iso3c using "$raw_data/WorldPop/pop_density_90.dta"

// Cutoff for COVID stringency:
// We set a cutoff for COVID stringency as above 40 on the Oxford index.

gen tr = 1 if oxcgrtstringency > 50
replace tr = 0 if oxcgrtstringency <= 50
replace tr = . if missing(oxcgrtstringency)

// countries treated:
bys iso3c: egen tr_at_all = max(tr)
drop if missing(tr_at_all)

// get treatment start date
bys iso3c: egen tr_year = min(year) if tr == 1
bys iso3c: egen tr_month = min(month) if tr == 1
assert tr_year == . if tr_at_all == .
assert tr_month == . if tr_at_all == .

// each country should only have 1 treatment start date
preserve
keep iso3c tr_year tr_month
duplicates drop
drop if mi(tr_year) & mi(tr_month)
check_dup_id "iso3c"
restore

bys iso3c: fillmissing tr_year tr_month
br iso3c year month tr tr_year tr_month
assert tr_year != . if tr_at_all == 1
assert tr_month != . if tr_at_all == 1

keep ln_del_sum_pix_area iso3c year month tr tr_year tr_month tr_at_all cat_year cat_month cat_iso3c
g ttt = 12*(year - tr_year) + (month-tr_month)
drop if mi(ln_del_sum_pix_area)

gen post_tr = 1 if ttt >= 0
replace post_tr = 0 if ttt < 0

label variable iso3c "country"
label variable year "year"
label variable month "month"
label variable ln_del_sum_pix_area "Log VIIRS (cleaned) / area"
label variable tr "Whether the country was above this lockdown threshold in this month"
label variable tr_at_all "Did the country experience lockdown at all?"
label variable tr_year "Year of lockdown"
label variable tr_month "Month of lockdown"
label variable ttt "Time to lockdown (months)"
label variable post_tr "Is this after lockdown?"
br
save "$input/ox_event_study.dta", replace

// merge in built population density NTL:

use "$raw_data/WorldPop/pop_density_90.dta", clear
keep iso3c year month pol_area pos_sumpx
check_dup_id "iso3c year month"
assert pos_sumpx>=0
assert pol_area>=0
gen ln_del_sum_pix_area_90_cut = ln(pos_sumpx/pol_area)
keep ln_del_sum_pix_area_90_cut iso3c year month
naomit

mmerge iso3c year month using "$input/ox_event_study.dta"
drop _merge
save "$input/ox_event_study.dta", replace


// RUN REGRESSIONS --------------------------------

foreach i in covid_response_3 {
	global `i' "$input/`i'.xls"
	noisily capture erase "`i'.xls"
	noisily capture erase "`i'.txt"
	noisily capture erase "`i'.tex"
}

use "$input/ox_event_study.dta", clear

#delimit ;
	eventdd ln_del_sum_pix_area, hdfe absorb(i.cat_year i.cat_iso3c i.cat_month) 
	timevar(ttt) ci(rcap) cluster(cat_iso3c) inrange lags(10) leads(40) 
	graph_op(ytitle("Log Lights / Area") xlabel(-40(5)10));
#delimit cr
gr_edit .style.editstyle declared_xsize(50) editcopy
gr_edit .style.editstyle declared_ysize(50) editcopy
graph export "$output/event_study_CI.pdf", replace
	
outreg2 using "covid_response_3.tex", append ///
	label dec(3) ///
	bdec(3) addstat(Countries, e(N_clust), ///
	Adjusted Within R-squared, e(r2_a_within), ///
	Within R-squared, e(r2_within))

reghdfe ln_del_sum_pix_area post_tr, absorb(i.cat_year i.cat_iso3c i.cat_month) vce(cluster cat_iso3c)
outreg2 using "covid_response_3.tex", append ///
	label dec(3) keep (post_tr) ///
	bdec(3) addstat(Countries, e(N_clust), ///
	Adjusted Within R-squared, e(r2_a_within), ///
	Within R-squared, e(r2_within))

////////////////
#delimit ;
	eventdd ln_del_sum_pix_area_90_cut, hdfe absorb(i.cat_year i.cat_iso3c i.cat_month) 
	timevar(ttt) ci(rcap) cluster(cat_iso3c) inrange lags(10) leads(40) 
	graph_op(ytitle("Log Lights / Area") xlabel(-40(5)10));
#delimit cr
gr_edit .style.editstyle declared_xsize(50) editcopy
gr_edit .style.editstyle declared_ysize(50) editcopy
graph export "$output/event_study_CI.pdf", replace

outreg2 using "covid_response_3.tex", append ///
	label dec(3) ///
	bdec(3) addstat(Countries, e(N_clust), ///
	Adjusted Within R-squared, e(r2_a_within), ///
	Within R-squared, e(r2_within))

reghdfe ln_del_sum_pix_area_90_cut post_tr, absorb(i.cat_year i.cat_iso3c i.cat_month) vce(cluster cat_iso3c)
outreg2 using "covid_response_3.tex", append ///
	label dec(3) keep (post_tr) ///
	bdec(3) addstat(Countries, e(N_clust), ///
	Adjusted Within R-squared, e(r2_a_within), ///
	Within R-squared, e(r2_within))
	

exit
// =============================================================================

// ARCHIVED OLD CODE
//
//
// use "$input/month_iso3c_cleaned.dta", clear
//
// // generate datasets to be used for graphs:
// foreach i of varlist oxcgrt* cornet* {
// 	use "$input/month_iso3c_cleaned.dta", clear
// 	keep if ttt_`i' >= -3 & ttt_`i' <= 2
// 	keep ttt_`i' ln_del_sum_pix_area g_an_ln_del_sum_pix_area iso3c year month `i'
// 	sort iso3c year month
// 	collapse (mean) ln_del_sum_pix_area g_an_ln_del_sum_pix_area, by(iso3c ttt_`i')
// 	naomit
// 	g index = "`i'"
// 	rename ttt* ttt
// 	save "$input/graphs_pre_post_peak_`i'_diff.dta", replace
// }
//
// clear
// use "$input/month_iso3c_cleaned.dta", clear
// drop if year < 1000000000000
// foreach i of varlist oxcgrt* cornet* {
// 	append using "$input/graphs_pre_post_peak_`i'_diff.dta", force
// }
// keep ttt ln_del_sum_pix_area g_an_ln_del_sum_pix_area iso3c index
// save "$input/event_study_ntl_covid.dta", replace
//
//
//
// // RUN REGRESSIONS ----------------------------------------------------------
//
// foreach i in covid_response_1 covid_response_2 covid_response_3 {
// 	global `i' "$input/`i'.xls"
// 	noisily capture erase "`i'.xls"
// 	noisily capture erase "`i'.txt"
// 	noisily capture erase "`i'.tex"
// }
//
// // mean across all:
// use "$input/month_iso3c_cleaned.dta", clear
//
// collapse (mean) cornet* oxcgrt* g_an_ln_del_sum_pix_area, by(iso3c year)
// naomit
// reg g_an_ln_del_sum_pix_area cornet* oxcgrt*, vce(hc3)
// outreg2 using "covid_response_1.tex", append label dec(3)
// foreach y in g_an_ln_del_sum_pix_area {
// 	foreach x of varlist cornet* oxcgrt* {
// 		reg `y' `x', vce(hc3)
// 		outreg2 using "covid_response_1.tex", append label dec(3)
// 	}
// }
//
//
// // country fixed effects:
//
// use "$input/month_iso3c_cleaned.dta", clear
// reghdfe g_an_ln_del_sum_pix_area cornet* oxcgrt*, absorb(cat_iso3c) vce(cluster cat_iso3c)
//
// outreg2 using "covid_response_2.tex", append ///
// label dec(3) keep (`x') ///
// bdec(3) addstat(Countries, e(N_clust), ///
// Adjusted Within R-squared, e(r2_a_within), ///
// Within R-squared, e(r2_within))
//
// foreach y in g_an_ln_del_sum_pix_area {
// 	foreach x of varlist cornet* oxcgrt* {
// 		reghdfe `y' `x', absorb(cat_iso3c) vce(cluster cat_iso3c)
//		
// 		outreg2 using "covid_response_2.tex", append ///
// 		label dec(3) keep (`x') ///
// 		bdec(3) addstat(Countries, e(N_clust), ///
// 		Adjusted Within R-squared, e(r2_a_within), ///
// 		Within R-squared, e(r2_within))
// 	}
// }
//
// // robust OLS: 
//
// use "$input/month_iso3c_cleaned.dta", clear
// reg g_an_ln_del_sum_pix_area cornet* oxcgrt*, vce(hc3)
// outreg2 using "covid_response_3.tex", append label dec(3)
//
// foreach y in g_an_ln_del_sum_pix_area {
// 	foreach x of varlist cornet* oxcgrt* {
// 		reg `y' `x', vce(hc3)
// 		outreg2 using "covid_response_3.tex", append label dec(3)
// 	}
// }
//
//
//
//
// // -------------------------------------------------------------------------
// // -------------------------------------------------------------------------
// // at the country-month-level, are there associations between lights and covid indicators?
//
// use "$input/clean_validation_monthly_base.dta", clear
//
// // reghdfe ln_sum_pix cornet* oxcgrt*, absorb(cat_iso3c cat_month) vce(cluster cat_iso3c)
// // outreg2 using "covid_response.xls", append ///
// // 		label dec(3) keep (cornet* oxcgrt*) ///
// // 		bdec(3) addstat(Countries, e(N_clust), ///
// // 		Adjusted Within R-squared, e(r2_a_within), ///
// // 		Within R-squared, e(r2_within))
//
// reghdfe g_an_ln_del_sum_pix_area cornet* oxcgrt*, absorb(cat_iso3c cat_month) vce(cluster cat_iso3c)
//
// outreg2 using "covid_response.tex", append ///
// 	label dec(3) keep (`x') ///
// 	bdec(3) addstat(Countries, e(N_clust), ///
// 	Adjusted Within R-squared, e(r2_a_within), ///
// 	Within R-squared, e(r2_within))
//
// outreg2 using "covid_response.xls", append ///
// 	label dec(3) keep (cornet* oxcgrt*) ///
// 	bdec(3) addstat(Countries, e(N_clust), ///
// 	Adjusted Within R-squared, e(r2_a_within), ///
// 	Within R-squared, e(r2_within))
//
// foreach y in g_an_ln_del_sum_pix_area { //ln_sum_pix {
// 	foreach x of varlist cornet* oxcgrt* {
// 		reghdfe `y' `x', absorb(cat_iso3c cat_month) vce(cluster cat_iso3c)
//		
// 		outreg2 using "covid_response.xls", append ///
// 		label dec(3) keep (`x') ///
// 		bdec(3) addstat(Countries, e(N_clust), ///
// 		Adjusted Within R-squared, e(r2_a_within), ///
// 		Within R-squared, e(r2_within))
//		
// 		outreg2 using "covid_response.tex", append ///
// 		label dec(3) keep (`x') ///
// 		bdec(3) addstat(Countries, e(N_clust), ///
// 		Adjusted Within R-squared, e(r2_a_within), ///
// 		Within R-squared, e(r2_within))
//		
// // 		// -------------------------------------------------
// // 		regress `y' `x' i.cat_iso3c##i.cat_month, robust
// //		
// // 		outreg2 using "covid_response.xls", append ///
// // 		label dec(3) keep (`x' i.cat_month) ///
// // 		bdec(3) 
// 	}
// }
//
// // Diff in Diff -------------------------------------------------------------
//
// // Is there a drop in NTL after March at the ADM2 level?
//
// cd "$input"
//
// foreach i in covid_response2 {
// 	global `i' "$input/`i'.xls"
// 	noisily capture erase "`i'.xls"
// 	noisily capture erase "`i'.txt"
// 	noisily capture erase "`i'.tex"
// }
//
// forval percentile = 0(20)80 { 
// use "$input/adm2_month_derived.dta", replace
// keep ln_del_sum_pix_area g_an_ln_del_sum_pix_area after_march cat_objectid cat_yr cat_objectid
// naomit
// centile ln_del_sum_pix_area, centile(`percentile')
// local perc `r(c_1)'
// drop if cat_yr <= 3
// drop if ln_del_sum_pix_area < `perc'
//
// reghdfe g_an_ln_del_sum_pix_area c.after_march##i.cat_yr, absorb(cat_objectid) vce(cluster cat_objectid)
// outreg2 using "covid_response2.tex", append ///
// 	label dec(3) keep (c.after_march##i.cat_yr) ///
// 	bdec(3) addstat("ADM2 Regions", e(N_clust), ///
// 	Adjusted Within R-squared, e(r2_a_within), ///
// 	Within R-squared, e(r2_within)) ///
// 	title("`percentile'")
//
// }
//
// // Table:
// // Create table of differences at different *quantiles* of NTL
//
// tempfile difftable
// 	clear
// 	set obs 1
// 	gen year = 0
// 	gen premar = 0
// 	gen postmar = 0
// 	gen dd = 0
// save `difftable'
//
// forval percentile = 0(20)80 { 
// use "$input/adm2_month_derived.dta", replace
// keep ln_del_sum_pix_area g_an_ln_del_sum_pix_area after_march cat_objectid cat_yr cat_objectid
// naomit
// centile ln_del_sum_pix_area, centile(`percentile')
// local perc `r(c_1)'
// drop if cat_yr <= 3
// drop if ln_del_sum_pix_area < `perc'
//
// collapse (mean) g_an_ln_del_sum_pix_area, by(cat_yr after_march)
// reshape wide g_an_ln_del_sum_pix_area, i(cat_yr) j(after_march)
// rename (g_an_ln_del_sum_pix_area0 g_an_ln_del_sum_pix_area1) (premar postmar)
// gen dd = postmar - premar
// decode cat_yr, gen(year)
// destring year, replace
// drop cat_yr
// gen percentile = `percentile'
//
// append using `difftable'
// save `difftable', replace
// }
//
// clear
// use `difftable'
// sort percentile year
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
