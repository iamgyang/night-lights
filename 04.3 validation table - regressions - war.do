local sample 0
if (`sample' == 1) {
	di "YOU ARE USING A TEST SAMPLE OF THE DATA"
}
else if (`sample' != 1) {
	di "YOU ARE USING ALL THE DATA"
}


// DEFINE CUTOFF FOR TREATMENT ----------------------------------------------
foreach treat_var in affected deaths {
foreach pctile in 90 60 80 40 20 {
foreach week_restriction in "duration greater than three weeks" " " {

if (`sample' == 1) {
	use "$input/sample_war_nat_disaster_event_prior_to_cutoff.dta", clear
}
else {
	use "$input/war_nat_disaster_event_prior_to_cutoff.dta", clear	
}

// get percentile values
preserve
drop if `treat_var' <= 0 | missing(`treat_var')
centile `treat_var', centile(`pctile')
local perc `r(c_1)'
restore

// just display the percentile so that I can diagnose problems
foreach n in 1 1 1 1 1 1 1 {
	di `perc'
}

// treatment value if greater than this percentile value
gen tr = 1 if `treat_var' >= `perc'


// do not define treatment for any event that lasted less than 1 week's time
if ("`week_restriction'" == "duration greater than three weeks") {
	replace tr = 0 if `treat_var'_dur <= 3*7
}
replace tr = 0 if `treat_var' < `perc'
replace tr = . if missing(`treat_var')

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

keep ln_del_sum_pix_area objectid year month tr tr_year tr_month tr_at_all cat_year cat_month cat_objectid
g ttt = 12*(year - tr_year) + (month-tr_month)

gen post_tr = 1 if ttt >= 0
replace post_tr = 0 if ttt < 0 | missing(ttt)

label variable objectid "ADM2"
label variable year "year"
label variable month "month"
label variable ln_del_sum_pix_area "Log VIIRS (cleaned) / area"
label variable tr "Whether the country was above `perc' `treat_var' (`pctile' percentile) this month"
label variable tr_at_all "Did the country experience >`perc' `treat_var' in a month at all?"
label variable tr_year "Year of event start"
label variable tr_month "Month of event start"
label variable ttt "Time to event start (months)"
label variable post_tr "Is this after event start?"

save "$input/`treat_var'_disaster_event_study_`pctile'_percentile_`week_restriction'.dta", replace
}
}
}

// RUN REGRESSIONS --------------------------------

// first delete all the regression table files:
foreach i in war_response_1 {
	noisily capture erase "$output/`i'.xls"
	noisily capture erase "$output/`i'.txt"
	noisily capture erase "$output/`i'.tex"
}

foreach week_restriction in "duration greater than three weeks" " " {
foreach treat_var in affected deaths {
foreach pctile in 90 60 80 40 20 {

use "$input/`treat_var'_disaster_event_study_`pctile'_percentile_`week_restriction'.dta", clear

keep if ((ttt <= 30) & (ttt>=-30)) | (missing(ttt))

#delimit ;
	eventdd ln_del_sum_pix_area, hdfe absorb(i.cat_year i.cat_objectid i.cat_month) 
	timevar(ttt) ci(rcap) cluster(cat_objectid) inrange lags(30) leads(30) 
	graph_op(ytitle("Log Lights / Area") xlabel(-30(5)30))
	;
#delimit cr
gr export "$output/event_study_`treat_var'_`pctile'_`week_restriction'.png", as(png) width(3000) height(2000) replace

outreg2 using "$output/war_response_1.tex", append ///
	label dec(3) ///
	bdec(3) addstat(Countries, e(N_clust), ///
	Adjusted Within R-squared, e(r2_a_within), ///
	Within R-squared, e(r2_within)) ///
	title(">`perc' `treat_var'" "(`pctile' percentile) `week_restriction'")

reghdfe ln_del_sum_pix_area post_tr, absorb(i.cat_year i.cat_objectid i.cat_month) vce(cluster cat_objectid)
outreg2 using "$output/war_response_1.tex", append ///
	label dec(3) keep (post_tr) ///
	bdec(3) addstat(Countries, e(N_clust), ///
	Adjusted Within R-squared, e(r2_a_within), ///
	Within R-squared, e(r2_within)) ///
	title(">`perc' `treat_var'" "(`pctile' percentile) `week_restriction'")
}
}
}

cls
foreach week_restriction in "duration greater than three weeks" " " {
foreach treat_var in affected deaths {
foreach pctile in 90 60 80 40 20 {

if ("`treat_var'" == "affected") {
	loc treat_var "Natural Disaster"
}
else if ("`treat_var'" == "deaths") {
	loc treat_var "Wars"
}

di "`treat_var' `pctile'th Percentile `week_restriction'"
di "`treat_var' `pctile'th Percentile `week_restriction'"


}
}
}

