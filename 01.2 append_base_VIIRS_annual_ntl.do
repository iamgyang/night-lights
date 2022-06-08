// There are two sources of the VIIRS data, annual and monthly. This cleans and
// appends all the ANNUAL ADM2 level VIIRS night lights into 1 file. This data
// was cleaned by NASA.

// NEW VIIRS (annual) ----------------------------------------------------

import delimited "$raw_data/VIIRS NTL Extracted Data 2 2012-2020/VIIRS_annual2.csv", clear

// generate time variable and adjust for the same names as the prior dataset
	tostring year, gen(time)
	replace time = substr(time, 3, 4)
	replace time = "Jan_" + time
	rename (r_mean r_sd r_sum) (mean_pix std_pix sum_pix)

// clean dates
	gen date2 = date(time, "M20Y")	
	format date2 %td
	gen yq = qofd(date2)
	format yq %tq

// in other datasets, Kosovo is XKX
	replace iso3c = "XKX" if iso3c == "XKO"

// check that GID is the same as ISO ID
	preserve
	keep iso3c name_0
	gduplicates drop
	kountry name_0, from(other) stuck
	ren(_ISO3N_) (temp)
	kountry temp, from(iso3n) to(iso3c)
	sort _ISO3C_
	gen iso_same = _ISO3C_ == iso3c
	replace iso_same = 1 if _ISO3C_ == ""
	assert iso_same == 1
	restore
	
// Clean up: 
	replace gid_2 = ""   if gid_2   == "NA"
	replace gid_1 = ""   if gid_1   == "NA"
	replace name_0 = ""  if name_0  == "NA"
	replace iso3c = ""   if iso3c 	== "NA"
	replace name_1 = ""  if name_1 	== "NA"

// Save NEW VIIRS DATASET
	save "$input/NTL_appended2.dta", replace
	


