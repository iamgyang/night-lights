// Macros ----------------------------------------------------------------

clear all 
set more off
set varabbrev off
set scheme s1mono
set type double, perm

// CHANGE THIS!! --- Define your own directories:
foreach user in "`c(username)'" {
	global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
}

global code        "$root/HF_measures/code"
global input       "$root/HF_measures/input"
global output      "$root/HF_measures/output"
global raw_data    "$root/raw-data"
global ntl_input   "$root/raw-data/VIIRS NTL Extracted Data 2012-2020"

// CHANGE THIS!! --- Do we want to install user-defined functions?
loc install_user_defined_functions "No"

if ("`install_user_defined_functions'" == "Yes") {
	foreach i in rangestat wbopendata kountry mmerge outreg2 somersd ///
	asgen moss reghdfe ftools fillmissing {
		ssc install `i'
	}
}


// ==========================================================================

cd "$input"
	
*** Gross Regional Product ---------------------------------
import excel "$raw_data/National Accounts/China_GRP_Quarterly_Province.xlsx", ///
	sheet("Gross_Regional_Product") cellrange(A2:AG35) firstrow clear

destring Quarter Year, replace
foreach x of varlist Beijing-Xinjiang {
	rename `x' GRP`x'
}
reshape long GRP, i(Quarter Year) j(province, string)
rename *, lower

// check we don't have duplicates:
sort quarter year grp
quietly by quarter year grp:  gen dup = cond(_N==1,0,_n)
assert dup == 0
drop dup

save "$input/grp_china_adm1.dta", replace

// Household Consumption --------------------------------------
import excel "$raw_data/National Accounts/China_GRP_Quarterly_Province.xlsx", ///
	sheet("Household_Living_Condition2") firstrow clear
destring quarter year, replace

// check that each province has the same number of rows:
gen count = 1
sort Province
by Province: egen check = sum(count)
egen check2 = max(check)
assert check == check2
drop check* count

// check that each year and quarter is represented:
fillin year quarter Province
drop if _fillin == 1 & year == 2021 & (quarter == 3 | quarter == 4)
assert _fillin == 0
drop _fillin

// // Check that we don't have duplicated VALUES by quarter and year:
// // I manually did this, and they all matched the original data on 
// // https://data.stats.gov.cn/english/easyquery.htm?cn=E0102
// // although, I'm not sure what to make of the frequency of duplicated values?
// pause on
// foreach x of varlist PerCapitaDisposableIncomeNat-PerCapitaExpenditureofRural{
// 	di "`x'"
// 	sort quarter year `x'
// 	quietly by quarter year `x':  gen dup = cond(_N==1,0,_n)
// 	br if dup != 0
// 	pause "`x'"
// // 	assert dup == 0
// 	drop dup
// }
// pause off

// rename variables:
#delimit ;
	rename (
		PerCapitaDisposableIncomeNat 
		PerCapitaDisposableIncomeof 
		F 
		PerCapitaExpenditureNationwid 
		PerCapitaExpenditureofUrban 
		PerCapitaExpenditureofRural
		) (
		disp_income_pc
		disp_income_urban_pc
		disp_income_rural_pc
		exp_pc
		exp_urban_pc
		exp_rural_pc
		);
#delimit cr

rename *, lower

save "$input/hhs_china_adm1.dta", replace



















