import excel  "C:/Users/user/Dropbox/CGD GlobalSat/raw-data/National Accounts/IND/India_State_wise_GDP growth rates.xls", clear
assert L[4] == "(% Growth over previous year)"
assert L[5] == "2012-13"
drop L M N O P Q R S
drop A
drop if B == ""
destring C-K, replace force
foreach i of numlist 2011/2019 {
    loc a = `"`a' x`i'"'
	di "`a'"
}
rename(C D E F G H I J K) (`a')
drop if mi(x2011)
reshape long x, i(B) j(year)
rename (x B) (GRP region)
naomit
gen note = "Net constant gross value added"
gen iso3c = "IND"
save "$input/india_subnatl_grp.dta", replace
