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
gen revision = 1
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
gen revision = 2
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
gen revision = 3
tempfile third
save `third'

// append
clear
use `first'
append using `second'
append using `third'

// remove duplicates by defaulting to the most recent revision of subnational GRP
bys region year: gen n = _N
br if n != 1
bys region year: gegen rev_recent = max(revision)
replace GRP = . if revision != rev_recent
gcollapse (mean) GRP, by(region year)
assert !mi(region)
assert !mi(year)
gen iso3c = "IND"

// save
save "$input/india_subnatl_grp.dta", replace
.