use "$raw/Black Marble NTL/bm_adm2_05-09-2022.dta", clear

// NOTE: THERE ARE STILL SOME SEVERE MATCHING PROBLEMS -- NEED TO CONFIRM WITH
// PARTH HERE (COUNTRY DOES NOT MATCH ISO3C)

// create variables of interest
    gen ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
    gen ln_sum_pix_bm_area = ln(sum_pix_bm/pol_area)
    gen ln_sum_pix_bm_dec_area = ln(sum_pix_bm_dec/pol_area)
    create_logvars "GRP del_sum_pix sum_pix_bm_dec sum_pix_bm"
    label variable ln_del_sum_pix_area "Log(VIIRS pixels/area)"
    label variable ln_sum_pix_bm_dec_area "Log(BM Dec. pixels/area)"
    label variable ln_sum_pix_bm_area "Log(BM pixels/area)"
    label variable ln_GRP "Log(Gross Regional Product)"

	// label the OECD variables
    label_oecd iso3c
	
	// create categorical variables
	create_categ(objectid iso3c year)

// save:
save "$input/ADM2_GDP.dta", replace
