// This file cleans the black marble p.m. to data. The black marble area them to
// data comes originally from in our data file that Park provides. That our data
// file is been converted to a DTA file within an hour. This file converts that
// DTA file into different aggregations of the Black Marble data (ADM2 - month,
// ADM2 - year, ISO3C - year). Note that when comparing the Black Marble data to
// VIIRS data, there are some discrepancies with polygon area. This is due to
// something called "raster extent". (ask Parth)

use "$raw_data/Black Marble NTL/bm_adm2.dta", clear
decode_vars, all
rename *, lower
rename bm_sumpix sum_pix_bm
quietly capture drop mon year

// replace missing variables
foreach i in gid_1 name_1 gid_0 name_0 {
    quietly capture replace `i' = "" if `i' == "."
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
quietly capture rename gid_0 iso3c
replace iso3c = "XKX" if iso3c == "XKO"
keep objectid sum_pix_bm pol_area iso3c gid_1 gid_2 year month name_1

// assert !mi(iso3c) & !mi(gid_1) & !mi(name_1) // !!!!!!!!!!!! SOME PROBLEM WITH THE DATA?!
drop if mi(iso3c) | mi(gid_1) | mi(name_1)

save "$input/bm_adm2_month.dta", replace
use "$input/bm_adm2_month.dta", clear

// COLLAPSING -----------------------------------------------------------

// collapse to an ADM2 level:
    gcollapse (sum) sum_pix_bm pol_area, by(iso3c year month gid_1 name_1)
	save "$input/bm_adm1_month.dta", replace

// collapse across country & month
    gcollapse (sum) sum_pix_bm pol_area, by(iso3c year month)
    
    // CHECKS -----------------------------------------------------------
        // make sure that across time, the polygon area remains the same
        preserve
        sort iso3c year month
        by iso3c:gen pol_area_L1 = pol_area[_n-1]
        assert abs(pol_area_L1 - pol_area) < 1 if !mi(pol_area_L1)

        // compare polygon area with polygon area of other VIIRS aggregation
        keep pol_area iso3c
        gduplicates drop
        tempfile areas
        save `areas'
        use "$input/iso3c_year_viirs_new.dta", clear
        keep sum_area iso3c
        rename sum_area other_pol_area
        gduplicates drop
        mmerge iso3c using `areas'
        keep if _merge == 3
        pause checking polygon area
        // assert abs(pol_area - other_pol_area) < 1 !!!!!!! polygon area
        // doesn't match up? parth says something to do with raster "extent"...
        restore

	// export
    save "$input/bm_iso3c_month.dta", replace

// collapse across years

use "$input/bm_adm1_month.dta", clear

gcollapse (sum) sum_pix_bm (mean) pol_area, by(iso3c gid_1 name_1 year)

foreach i in iso3c gid_1 name_1 year {
    drop if mi(`i')
}

save "$input/bm_adm1_year.dta", replace

// collapse by year and country
gcollapse (sum) sum_pix_bm pol_area, by(iso3c year)

drop if mi(iso3c) | mi(year)

save "$input/bm_iso3c_year.dta", replace



