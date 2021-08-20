// Macros ---------------------------------------------------------------------
foreach user in "`c(username)'" {
	global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
	global hf_input "$root/HF_measures/input/"
	global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
}
set more off 
cd "$hf_input"

// ----------------------------------------------------------------------------

// get MEAN(log(X_{t})-log(X_{t-1})), and MEAN(GDP, pcap, PPP from WDI, PWT, 
// Oxford, NTL w/ neg removed, NTL w/o neg removed)
// make sure we have a balanced panel

// create dataset of NTL with deletions and without month-ADM2 deletions.
local del "delete not_delete"

foreach i in `del' {
	use "$hf_input/NTL_GDP_month_ADM2.dta", clear
	keep iso3c gid_2 mean_pix sum_pix year quarter month pol_area pwt_rgdpna ///
	WDI ox_rgdp_lcu
	if ("`i'" == "delete") {
		drop if sum_pix < 0	    
	}
	rename pol_area sum_area
	collapse (sum) sum_area sum_pix (mean) pwt_rgdpna WDI ///
	ox_rgdp_lcu, by(year quarter iso3c)
	rename (ox_rgdp_lcu pwt_rgdpna WDI) (Oxford PWT WDI)
	sort iso3c year
	collapse (sum) sum_area sum_pix Oxford ///
	(mean) PWT WDI, by(year iso3c)
	replace Oxford = . if Oxford  == 0
	duplicates tag iso3c year, gen(dup)
	assert dup == 0
	drop dup
	save "collapsed_dataset_`i'.dta", replace
}

use "collapsed_dataset_delete.dta", clear
rename (sum_area sum_pix) (del_sum_area del_sum_pix)
mmerge iso3c year using "collapsed_dataset_not_delete.dta"
assert _m == 3
drop _m

// merge in population
mmerge iso3c year using "un_pop_estimates_cleaned.dta"
keep if _m == 3
drop _m

// create per capita figures
foreach i in Oxford PWT WDI {
    replace `i' = `i' * (10^9)
}
gen del_sum_pix_area = del_sum_pix / del_sum_area
foreach i in del_sum_pix Oxford PWT WDI sum_pix {
    replace `i' = `i' / poptotal
}

// get the GDP at the start
sort iso3c year
gen begin_year = year if PWT!=.
bysort iso3c: egen begin_yr = min(begin_year)
drop begin_year
gen start_gdppc_pwt_0 = PWT if year == begin_yr
bysort iso3c: egen start_gdppc_pwt = mean(start_gdppc_pwt_0)
drop start_gdppc_pwt_0
assert begin_yr == 2012 | begin_yr == .

// get growth
sort iso3c year

foreach var in del_sum_pix Oxford PWT WDI sum_pix start_gdppc_pwt del_sum_pix_area {
generate ln_`var' = ln(`var')
}
fillin iso3c year
assert _fillin == 0
drop _fillin

foreach var in ln_del_sum_pix ln_Oxford ln_PWT ln_WDI ln_sum_pix ln_del_sum_pix_area {
generate g_`var' = `var' - `var'[_n-1] if iso3c==iso3c[_n-1]
}

// collapse with a mean
collapse (mean) g_ln_del_sum_pix g_ln_Oxford g_ln_PWT g_ln_WDI g_ln_sum_pix ///
ln_PWT ln_start_gdppc_pwt g_ln_del_sum_pix_area, by(iso3c)

// same country composition (147 countries)
foreach i in g_ln_del_sum_pix g_ln_Oxford g_ln_PWT g_ln_WDI g_ln_sum_pix ///
ln_PWT ln_start_gdppc_pwt g_ln_del_sum_pix_area {
    drop if `i' == .
}

save "angrist_replication_with_new_data_2.dta", replace

// create the graph
// X axis is BEGINNING GDP -------------------------------------------------
set scheme plotplainblind
#delimit;
graph twoway
lowess g_ln_del_sum_pix ln_start_gdppc_pwt, yline(0) xscale(log) xline(9.5 8.5 7.5, lcolor(gray*.4))  ||
lowess g_ln_sum_pix ln_start_gdppc_pwt, yline(0) xscale(log) xline(9.5 8.5 7.5, lcolor(gray*.4))  ||
lowess g_ln_PWT ln_start_gdppc_pwt, yline(0) xscale(log) xline(9.5 8.5 7.5, lcolor(gray*.4))  ||
lowess g_ln_WDI ln_start_gdppc_pwt, yline(0) xscale(log) xline(9.5 8.5 7.5, lcolor(gray*.4))  ||
lowess g_ln_Oxford ln_start_gdppc_pwt, yline(0) legend(pos(4) order(1 "Lights Negatives Removed" 2 "Lights" 3 "PWT" 4 "WDI" 5 "Oxford")) xscale(log) xline(9.5 8.5 7.5, lcolor(gray*.4)) ytitle("Growth") ylabel(, nogrid) xlabel(, nogrid)  ||
pcarrowi .25 7 .25 7  (6) "LIC" ///
.25 8 .25 8 (6) "LMIC" ///
.25 9 .25 9 (6) "UMIC" ///
.25 10 .25 10 (6) "HIC", mcolor(white) lcolor(white) 

xlabel(7 "1000" 8 "3000" 9 "8000" 10 "20000" 11 "55000") xtitle("Log GDP Per Capita (PWT) 2012")
ylabel(-.05(.05)0.25)
;
graph export "angrist_figure2_replication_2012-2020.pdf", replace;
#delimit cr

// X axis is MEAN GDP -------------------------------------------------
set scheme plotplainblind
#delimit;
graph twoway
lowess g_ln_del_sum_pix ln_PWT, yline(0) xscale(log) xline(9.5 8.5 7.5, lcolor(gray*.4))  ||
lowess g_ln_sum_pix ln_PWT, yline(0) xscale(log) xline(9.5 8.5 7.5, lcolor(gray*.4))  ||
lowess g_ln_PWT ln_PWT, yline(0) xscale(log) xline(9.5 8.5 7.5, lcolor(gray*.4))  ||
lowess g_ln_WDI ln_PWT, yline(0) xscale(log) xline(9.5 8.5 7.5, lcolor(gray*.4))  ||
lowess g_ln_Oxford ln_PWT, yline(0) legend(pos(4) order(1 "Lights Negatives Removed" 2 "Lights" 3 "PWT" 4 "WDI" 5 "Oxford")) xscale(log) xline(9.5 8.5 7.5, lcolor(gray*.4)) ytitle("Growth") ylabel(, nogrid) xlabel(, nogrid)  ||
pcarrowi .25 7 .25 7  (6) "LIC" ///
.25 8 .25 8 (6) "LMIC" ///
.25 9 .25 9 (6) "UMIC" ///
.25 10 .25 10 (6) "HIC", mcolor(white) lcolor(white) 

xlabel(7 "1000" 8 "3000" 9 "8000" 10 "20000" 11 "55000") xtitle("Mean Log GDP Per Capita (PWT) 2012-2020")
ylabel(-.05(.05)0.25)
;
graph export "angrist_figure2_replication_2012-2020_ORIGINAL.pdf", replace;
#delimit cr

// Y axis is LIGHTS/AREA -------------------------------------------------
set scheme plotplainblind
#delimit;
graph twoway
lowess g_ln_del_sum_pix_area ln_start_gdppc_pwt, yline(0) xscale(log) xline(9.5 8.5 7.5, lcolor(gray*.4))  ||
lowess g_ln_PWT ln_start_gdppc_pwt, yline(0) xscale(log) xline(9.5 8.5 7.5, lcolor(gray*.4))  ||
lowess g_ln_WDI ln_start_gdppc_pwt, yline(0) legend(pos(4) order(1 "Lights/Area Negatives Removed" 2 "PWT" 3 "WDI")) xscale(log) xline(9.5 8.5 7.5, lcolor(gray*.4)) ytitle("Growth") ylabel(, nogrid) xlabel(, nogrid)  ||
pcarrowi .25 7 .25 7  (6) "LIC" ///
.25 8 .25 8 (6) "LMIC" ///
.25 9 .25 9 (6) "UMIC" ///
.25 10 .25 10 (6) "HIC", mcolor(white) lcolor(white) 

xlabel(7 "1000" 8 "3000" 9 "8000" 10 "20000" 11 "55000") xtitle("Log GDP Per Capita (PWT) 2012")
ylabel(-.05(.05)0.25)
;
graph export "angrist_figure2_replication_2012_AREA.pdf", replace;
#delimit cr



