// Macros ---------------------------------------------------------------------
foreach user in "`c(username)'" {
	global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
	global hf_input "$root/HF_measures/input/"
	global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
}
set more off 
cd "$hf_input"

// -------------------------------------------------------------------------

// VIIRS cleaned & raw -----------------
// By cleaned, we mean NTL with deletions and without month-ADM2 deletions
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

tempfile viirs dmsp dmsp_hender

use "collapsed_dataset_delete.dta", clear
rename (sum_area sum_pix) (del_sum_area del_sum_pix)
mmerge iso3c year using "collapsed_dataset_not_delete.dta"
assert _m == 3
drop _m

// convert from billions:
foreach i in Oxford PWT WDI {
    replace `i' = `i' * (10^9)
}
gen del_sum_pix_area = del_sum_pix / del_sum_area

save `viirs'

// DMSP --------------------
import delimited "$hf_input/Nighttime_Lights_ADM2_1992_2013.csv", clear
collapse (sum) sum_light, by(countrycode year)
rename (countrycode sum_light) (iso3c sum_light_dmsp)
keep iso3c year sum_light_dmsp

save `dmsp'

// DMSP Henderson --------------------
use "$hf_input/HWS AER replication/hsw_final_tables_replication/global_total_dn_uncal.dta", clear
keep year iso3v10 country lngdpwdilocal lndn
rename iso3v10 iso3c
sort iso3c year
gen exp_hws_wdi = exp(lngdpwdilocal)

save `dmsp_hender'

// WB historical income classifications --------------
import excel "OGHIST_historical_WB_country_income_classification.xls", ///
sheet("Country Analytical History") allstring clear
gen rownum = _n
replace A = "colnames" if rownum == 5
drop if A == ""
drop rownum
unab varlist : *
capture quietly foreach v of local varlist {
    local value = `v'[1]
    local vname = strtoname(`"`value'"')
    rename `v' `vname'
    label var `vname' `"`value'"'
}
drop in 1
keep colnames FY*
capture quietly drop FY
foreach i of varlist * {
    replace `i' = "" if `i' == ".."
	replace `i' = "LIC" if `i' == "L"
	replace `i' = "LMIC" if `i' == "LM"
	replace `i' = "UMIC" if `i' == "UM"
	replace `i' = "HIC" if `i' == "H"
}
reshape long FY, i(colnames) j(year, string)
rename FY income
destring year, replace

// since it gives 2 digit fiscal years, we conver to 4 digit fiscal years
replace year = 1900 + year if year >= 50
replace year = 2000 + year if year < 50
drop if income == ""
rename colnames iso3c
save "historical_wb_income_classifications.dta", replace

// ---------------------------------------------------------------------
// Merge ---------------------------------------------------------------
// ---------------------------------------------------------------------

clear
use `viirs'
mmerge iso3c year using `dmsp'
drop _m
mmerge iso3c year using `dmsp_hender'
drop _m
mmerge iso3c year using historical_wb_income_classifications.dta
drop _m
mmerge iso3c year using un_pop_estimates_cleaned.dta
drop _m

// get balanced panel
fillin iso3c year
local thisyear: di %tdDNCY daily("$S_DATE", "DMY")
di "`thisyear'"
local thisyear = substr("`thisyear'", 5, 4)
drop if year > `thisyear'

// confirm that we only have 1 country-year in our panel
bysort iso3c year: gen dup = _n
assert dup == 1

drop _fillin dup

save clean_validation_base.dta, replace








