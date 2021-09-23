// Please run "00 master.do" to establish global macros prior.

// File appends all VIIRS night lights files into 1 file. 

// ================================================================
if ("$import_nightlights" == "yes") {
	import delimited "$ntl_input/NTL_adm2_2012.csv", encoding(UTF-8) clear 
	tempfile ntl_append
	save `ntl_append'

	foreach yr in 2013 2014 2015 2016 2017 2018 2019 2020 {
		import delimited "$ntl_input/NTL_adm2_`yr'.csv", encoding(UTF-8) clear 
		tempfile ntl_append_`yr'
		save `ntl_append_`yr''
		use `ntl_append', clear
		append using `ntl_append_`yr''
		save `ntl_append', replace
	}
	use `ntl_append'

// clean dates
	gen date2 = date(time, "M20Y")	
	format date2 %td
	gen yq = qofd(date2)
	format yq %tq

// in other datasets, Kosovo is XKX
	rename gid_0 iso3c
	replace iso3c = "XKX" if iso3c == "XKO"

// check that GID is the same as ISO ID
	preserve
	keep iso3c name_0
	duplicates drop
	kountry name_0, from(other) stuck
	ren(_ISO3N_) (temp)
	kountry temp, from(iso3n) to(iso3c)
	sort _ISO3C_
	gen iso_same = _ISO3C_ == iso3c
	replace iso_same = 1 if _ISO3C_ == ""
	assert iso_same == 1
	restore
}
else if ("$import_nightlights" != "yes") {
	use "$input/NTL_appended.dta", clear
}

// Clean up: 
	drop v1
	replace gadmid = ""  if gadmid  == "NA"
	replace iso = ""     if iso     == "NA"
	replace gid_2 = ""   if gid_2   == "NA"
	replace gid_1 = ""   if gid_1   == "NA"
	replace name_0 = ""  if name_0  == "NA"
	replace iso3c = ""   if iso3c 	== "NA"
	replace name_1 = ""  if name_1 	== "NA"

// Some ISO codes are in the ISO variable, as opposed to the ISO3C variable. 
// Similarly, we are missing some GADM codes
	replace iso3c = iso if (iso != "" & iso3c == "")
	replace gid_2 = "gadm" + gadmid if (gid_2 == "" & gadmid!="")

// save
	save "$input/NTL_appended.dta", replace






































