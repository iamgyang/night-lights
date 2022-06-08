// Import 3 excel spreadsheets and append them together in long format

// first spreadsheet
import excel "$raw_data/National Accounts/IND/India State GDP.XLSX", sheet("T_19(i)") cellrange(B6:G39) clear
assert C[1] == "2004-05"
assert G[1] == "2008-09"
destring C-G, replace force
drop if mi(C)
foreach i of numlist 2004/2008 {
    loc a = `"`a' x`i'"'
	di "`a'"
}
rename(C-G) (`a')
reshape long x, i(B) j(year)
rename (x B) (GRP region)
tempfile first
save `first'

// second spreadsheet
import excel "C:\Users\gyang\Dropbox\CGD GlobalSat\raw_data\National Accounts\IND\India State GDP.XLSX", sheet("T_19(ii)") cellrange(B6:G39) clear
assert C[1] == "2009-10"
assert G[1] == "2013-14"
destring C-G, replace force
drop if mi(C)
loc a
foreach i of numlist 2009/2013 {
    loc a = `"`a' x`i'"'
	di "`a'"
}
rename(C-G) (`a')
reshape long x, i(B) j(year)
rename (x B) (GRP region)
tempfile second
save `second'

// third spreadsheet
import excel "$raw_data/National Accounts/IND/India State GDP.XLSX", sheet("T_19(iii)") cellrange(B6:L41) clear
assert C[1] == "2011-12"
assert L[1] == "2020-21"
destring C-L, replace force
drop if mi(C)
loc a
foreach i of numlist 2011/2020 {
    loc a = `"`a' x`i'"'
	di "`a'"
}
rename(C-L) (`a')
reshape long x, i(B) j(year)
rename (x B) (GRP region)
naomit
tempfile third
save `third'

// append
clear
use `first'
append using `second'
append using `third'

// save
save "$input/india_subnatl_grp.dta", replace
.