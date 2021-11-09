// Right now, we're merging based on the mid-point of the war start period.
// As a future robustness check, merge based on the start point of the war start 
// period, and vary the death cutoff.


// merge in deaths data with night lights:
use "$raw_data/ucdp_war/aggregated_objectID_deaths.dta", clear
sort objectid month year
save "$raw_data/ucdp_war/aggregated_objectID_deaths.dta", replace

use "$input/NTL_VIIRS_appended_cleaned_all.dta", clear
sort objectid month year 
capture quietly drop _merge
mmerge objectid month year using "$raw_data/ucdp_war/aggregated_objectID_deaths.dta"

keep objectid iso3c del_sum_pix del_sum_area year month deaths cnf_dur _merge
drop _merge
fillin objectid year month
replace deaths = 0 if deaths == .
replace cnf_dur = 0 if cnf_dur == .
drop if missing(objectid)
check_dup_id "objectid year month"

// get outcome variable:
g ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
drop del_sum_pix del_sum_area _fillin iso3c

// DEFINE CUTOFF ----------------------
global treat "death"

// Cutoff for deaths:
if "$treat" == "death" {
	gen tr = 1 if deaths > 100
	replace tr = 0 if deaths <= 100
	replace tr = . if missing(deaths)
}

else if "$treat" == "duration" {
	sort objectid year month
	by objectid: gen tr = 1 if cnf_dur > 30 & cnf_dur[_n+1] > 30
	by objectid: replace tr = 0 if !(cnf_dur > 30 & cnf_dur[_n+1] > 30)
	replace tr = . if missing(cnf_dur)	
}

// countries treated:
bys objectid: egen tr_at_all = max(tr)
drop if missing(tr_at_all)

// get treatment start date
bys objectid: egen tr_year = min(year) if tr == 1
bys objectid: egen tr_month = min(month) if tr == 1
assert tr_year == . if tr_at_all == .
assert tr_month == . if tr_at_all == .

// ignore if we don't have objectID
drop if missing(objectid)

// each country should only have 1 treatment start date
preserve
keep objectid tr_year tr_month
duplicates drop
drop if mi(tr_year) & mi(tr_month)
check_dup_id "objectid"
restore

bys objectid: fillmissing tr_year tr_month
br objectid year month tr tr_year tr_month
assert tr_year != . if tr_at_all == 1
assert tr_month != . if tr_at_all == 1

// encode categorical variables (numeric --> categorical)
foreach i in year {
	gen str_`i' = string(`i')
	encode str_`i', gen(cat_`i')
	drop str_`i'
}

// encode categorical variables (character --> categorical)
foreach i in objectid {
    encode `i', gen(cat_`i')
}

// month has to be ordered
gen str_month = string(month)
label define str_month 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10" 11 "11" 12 "12"
encode str_month, generate(cat_month) label(str_month) 
drop str_month

keep ln_del_sum_pix_area objectid year month tr tr_year tr_month tr_at_all cat_year cat_month cat_objectid
g ttt = 12*(year - tr_year) + (month-tr_month)

gen post_tr = 1 if ttt >= 0
replace post_tr = 0 if ttt < 0 | missing(ttt)

label variable objectid "ADM2"
label variable year "year"
label variable month "month"
label variable ln_del_sum_pix_area "Log VIIRS (cleaned) / area"
label variable tr "Whether the country was above 30 deaths this month"
label variable tr_at_all "Did the country experience >30 deaths in a month at all?"
label variable tr_year "Year of war start"
label variable tr_month "Month of war start"
label variable ttt "Time to war start (months)"
label variable post_tr "Is this after war start?"

save "$input/war_event_study.dta", replace

// RUN REGRESSIONS --------------------------------

foreach i in war_response_1 {
	global `i' "$input/`i'.xls"
	noisily capture erase "`i'.xls"
	noisily capture erase "`i'.txt"
	noisily capture erase "`i'.tex"
}

use "$input/war_event_study.dta", replace

keep if ((ttt <= 10) & (ttt>=-20)) | (missing(ttt))

#delimit ;
	eventdd ln_del_sum_pix_area, hdfe absorb(i.cat_year i.cat_objectid i.cat_month) 
	timevar(ttt) ci(rcap) cluster(cat_objectid) inrange lags(10) leads(10) 
	graph_op(ytitle("Log Lights / Area") xlabel(-10(1)10));
#delimit cr
gr_edit .style.editstyle declared_xsize(50) editcopy
gr_edit .style.editstyle declared_ysize(50) editcopy
graph export "$output/event_study_war.pdf", replace

outreg2 using "war_response_1.tex", append ///
	label dec(3) ///
	bdec(3) addstat(Countries, e(N_clust), ///
	Adjusted Within R-squared, e(r2_a_within), ///
	Within R-squared, e(r2_within))

reghdfe ln_del_sum_pix_area post_tr, absorb(i.cat_year i.cat_objectid i.cat_month) vce(cluster cat_objectid)
outreg2 using "war_response_1.tex", append ///
	label dec(3) keep (post_tr) ///
	bdec(3) addstat(Countries, e(N_clust), ///
	Adjusted Within R-squared, e(r2_a_within), ///
	Within R-squared, e(r2_within))



















