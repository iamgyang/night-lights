// ================================================================

cd "$input"

// WDI population estimates --------------------------------------------------
clear
wbopendata, clear nometadata long indicator(SP.POP.TOTL) year(1960:2021)
drop if regionname == "Aggregates"
keep countrycode year sp_pop_totl
rename (countrycode sp_pop_totl) (iso3c poptotal)
fillin iso3c year
drop _fillin
sort iso3c year
bysort iso3c year: gen dup = _n
assert dup == 1
drop dup
br if poptotal ==.
replace poptotal = poptotal[_n-1] if poptotal == . & iso3c[_n] == iso3c[_n-1]

save "wb_pop_estimates_cleaned.dta", replace









