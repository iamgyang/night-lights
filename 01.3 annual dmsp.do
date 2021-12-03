tempfile dmsp dmsp_hender dmsp_goldberg

// DMSP from Australian website --------------------
import delimited "$raw_data/Other/Nighttime_Lights_ADM2_1992_2013.csv", clear
collapse (sum) sum_light, by(countrycode year)
rename (countrycode sum_light) (iso3c sum_light_dmsp)
keep iso3c year sum_light_dmsp

save `dmsp'

// DMSP Henderson --------------------
use "$raw_data/HWS AER replication/hsw_final_tables_replication/global_total_dn_uncal.dta", clear
keep year iso3v10 country lngdpwdilocal lndn wbdqtotal wbdqcat
rename iso3v10 iso3c
sort iso3c year
gen exp_hws_wdi = exp(lngdpwdilocal)

// WB statistical capacity from Henderson
gen wbdqcat_3 = "bad" if wbdqtotal<3.5
replace wbdqcat_3 = "ok" if wbdqtotal>3.5 & wbdqtotal<6.5
replace wbdqcat_3 = "good" if wbdqtotal>6.5

save `dmsp_hender'

// Goldberg DMSP data --------------------------------------------------

use "$raw_data/Angrist JEP replication/Data/Processed Data/master.dta", clear

// average
foreach var in g_ln_survey_fill g_ln_gdp g_ln_lights {
bys code: egen mean_`var' = mean(`var') if !missing(`var')
bys code: egen sd_`var' = sd(`var') if !missing(`var')
}
keep code year mean_g_ln_lights mean_g_ln_gdp g_ln_lights _gdppercap_constant_ppp lightpercap ln_gdp sumoflights
rename _gdppercap_constant_ppp rgdppc_ppp
rename * *_gold
rename (code_gold year_gold) (iso3c year)
foreach i of varlist *_gold {
    loc lab: variable label `i'
	label variable `i' "`lab' Goldberg"
}

save `dmsp_goldberg', replace

// merge -------------------------------

clear
use `dmsp'
capture quietly drop _merge
mmerge iso3c year using `dmsp_hender'
drop _merge
mmerge iso3c year using `dmsp_goldberg'
drop _merge

save "$input/all_dmsp.dta", replace



