use "$raw_data/Black Marble NTL/bm_ADM2_05-09-2022.dta", clear
rename BM_sumpix_dec sum_pix_bm_dec
rename *, lower
check_dup_id "objectid year reg_id"
rename objectid ADM2
rename value GRP

// convert country to iso3c as a check:
conv_ccode country
drop if iso != iso3c & !mi(iso3c) & !mi(iso)

// collapse to an ADM2 level (there are more regions to ADM2s)
gcollapse (sum) GRP (mean) pol_area sum_pix_bm_dec, by(ADM2 iso3c year)

// check
preserve
keep ADM2 pol_area
naomit
gduplicates drop
bys ADM2: gen n = _N
assert n == 1
restore

destring year, replace
// !!! we do not have many observations for 2019 (likely due to GRP data)
drop if year >= 2019

// create variables of interest
    gen ln_sum_pix_bm_dec_area = ln(sum_pix_bm_dec/pol_area)
    create_logvars "GRP sum_pix_bm_dec"
    label variable ln_sum_pix_bm_dec_area "Log(BM Dec. pixels/area)"
    label variable ln_GRP "Log(Gross Regional Product)"
	
	// label the OECD variables
    label_oecd iso3c
	
	// create categorical variables
	create_categ(ADM2 iso3c year)

// save:
save "$input/ADM2_year_aggregation.dta", replace
.