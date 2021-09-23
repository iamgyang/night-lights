
// WB historical income classifications --------------
import excel ///
"$raw_data/Other/OGHIST_historical_WB_country_income_classification.xls", ///
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
	replace `i' = "LMIC" if `i' == "LM*"
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




