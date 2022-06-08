/* This cleans all the subnational ADM1 GRP data and merges it with subnational VIIRS
and BM data */

/* First, load all the data ---------------------------------------------- */

/* India, Brazil, Indonesia, USA (note that the ADM1 mapping might not be
perfect) */
    use "$raw_data/National Accounts/geo_coded_data/global_subnational_ntlmerged_woPHL.dta", clear
    keep year region GRP iso3c_x gid_1 name_1
    rename iso3c_x iso3c_grp
    gen source = "country website"
    tempfile iibu
    save `iibu'
    clear

/* Global ADM1 GRP from OECD (note that ADM1 mapping might not be perfect) */
    use "$raw_data/National Accounts/geo_coded_data/oecd2_adm2NTL_map17feb22.dta", clear
    keep NAME_0 NAME_1 GID_1 iso3c regional_name
    rename *, lower
    decode_vars, all
    gduplicates drop
    naomit

    // import subnational GRP
    mmerge iso3c regional_name using "$input/oecd_tl2.dta"
    keep if _merge ==3 // !!!!!!! TODO: some were not geocoded accurately
    assert _merge == 3
    drop _merge
	conv_ccode name_0
	keep if iso3c == iso | mi(iso) | mi(iso3c) // !!!!!!! TODO: some were not geocoded accurately
	rename value GRP
    rename regional_name region
    rename iso3c iso3c_grp
	keep iso3c_grp region gid_1 name_1 GRP year
    gen source = "OECD"
    tempfile grp_oecd
    save `grp_oecd'
    clear

/* VIIRS night lights */
    use "$input/NTL_VIIRS_appended_cleaned_all.dta", clear
    keep objectid iso3c gid_1 year month del_sum_pix del_sum_area
    gcollapse (sum) del_sum_pix (mean) del_sum_area, by(objectid iso3c gid_1 year)
    gcollapse (sum) del_sum_pix del_sum_area, by(iso3c gid_1 year)
    label variable del_sum_pix "VIIRS (cleaned) sum of pixels"
    label variable del_sum_area "VIIRS (cleaned) polygon area" 
    tempfile viirs
    save `viirs'
    clear

/* black marble night lights */
    use "$input/bm_adm1_year.dta", clear
	naomit
    tempfile bm
    save `bm'
    clear

/* MERGE EVERYTHING! */
    append using `iibu'
    append using `grp_oecd'
    mmerge gid_1 year using `viirs'

    /* basically, one check is to make sure that the countries align -- they
    don't, unfortunately  // !!!!!!! some were not geocoded accurately */
    assert iso3c == iso3c_grp | mi(iso3c) | mi(iso3c_grp)
    keep if iso3c == iso3c_grp | mi(iso3c) | mi(iso3c_grp)
    drop iso3c
    drop _merge
    mmerge gid_1 year using `bm'
    assert iso3c == iso3c_grp | mi(iso3c) | mi(iso3c_grp)
    keep if iso3c == iso3c_grp | mi(iso3c) | mi(iso3c_grp)
    drop iso3c
    rename iso3c_grp iso3c
    drop _merge

    drop if mi(GRP) | mi(gid_1) | mi(year)

// drop if we got it directly from the country website (bettrer than OECD data)
    drop if (iso3c == "BRA" | iso3c == "IDN" | iso3c == "IND" | iso3c == "USA") & (source == "OECD")

// check duplicates
    // check_dup_id "gid_1 year"
    bys name_1 year: gen n = _N
    // br if n>1 !!!!!! some were not geocoded accurately again!
    keep if n==1

// collapse to OECD region level
    gcollapse (sum) del_sum_pix del_sum_area sum_pix_bm pol_area (mean) GRP, ///
        by(gid_1 iso3c year source)
    rename gid_1 region
	
	// remove fake zeros
	foreach i in del_sum_pix del_sum_area sum_pix_bm pol_area {
	    replace `i' = . if `i' == 0
	}
	
	scatter pol_area del_sum_area
	
// create variables of interest
    gen ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
    gen ln_sum_pix_bm_area = ln(sum_pix_bm/pol_area)
    create_logvars "GRP del_sum_pix sum_pix_bm"
    label variable ln_del_sum_pix_area "Log(VIIRS pixels/area)"
    label variable ln_sum_pix_bm_area "Log(BM pixels/area)"
    label variable ln_GRP "Log(Gross Regional Product)"

	// label the OECD variables
    label_oecd iso3c

    // change from "region" to "ADM1"
    rename region ADM1

	// create categorical variables
	create_categ(ADM1 iso3c year)

// save:
save "$input/adm1_year_aggregation.dta", replace
.