// Right now, we're merging based on the mid-point of the war start period. As a
// future robustness check, merge based on the start point of the war start
// period, and vary the death cutoff.

use "$raw_data/ucdp_war/aggregated_objectID_deaths.dta", clear
sort objectid month year
rename cnf_dur deaths_dur
check_dup_id "objectid month year"
save "$input/aggregated_objectID_deaths_cleaned.dta", replace

// merge in war data with night lights:
mmerge objectid month year using "$input/bm_adm2_month.dta"
sort objectid month year 

keep objectid iso3c sum_pix_bm pol_area year month deaths deaths_dur pol_area
replace deaths = 0 if deaths == .
replace deaths_dur = 0 if deaths_dur == .
drop if missing(objectid)
check_dup_id "objectid year month"

// create categorical variables
create_categ(year month objectid)

// get outcome variable:
gen ln_sum_pix_bm_area = ln(sum_pix_bm/pol_area)
label variable ln_sum_pix_bm_area "Log(BM pixels/area)"

save "$input/war_adm2_month.dta", replace
.