use "$raw_data/Black Marble NTL/bm_adm1_1322.dta", clear
decode_vars, all
rename *, lower

// replace missing variables
foreach i in gid_1 name_1 gid_0 name_0 {
    replace `i' = "" if `i' == "."
}

// create year and month variable
split time, parse(-) generate(year) limit(3) destring
rename (year1 year2) (mo year)
gen month = 999999
replace month = 1 if mo == "Jan"
replace month = 2 if mo == "Feb"
replace month = 3 if mo == "Mar"
replace month = 4 if mo == "Apr"
replace month = 5 if mo == "May"
replace month = 6 if mo == "Jun"
replace month = 7 if mo == "Jul"
replace month = 8 if mo == "Aug"
replace month = 9 if mo == "Sep"
replace month = 10 if mo == "Oct"
replace month = 11 if mo == "Nov"
replace month = 12 if mo == "Dec"
assert month != 999999 & !mi(month)
drop mo time

// kosovo
replace gid_0 = "XKX" if gid_0 == "XKO"
rename gid_0 iso3c

save "$input/bm_adm1_month.dta", replace

// assert !mi(iso3c) & !mi(gid_1) & !mi(name_1) // !!!!!!!!!!!! SOME PROBLEM WITH THE DATA?!

// collapse across years
gcollapse (sum) bm_sumpix (mean) pol_area, by(iso3c gid_1 name_1 year)

foreach i in iso3c gid_1 name_1 year {
    drop if mi(`i')
}

save "$input/bm_adm1_year.dta", replace

// collapse by year and country
gcollapse (sum) bm_sumpix pol_area, by(iso3c year)

drop if mi(iso3c) | mi(year)

save "$input/bm_iso3c_year.dta", replace



