/* List out the files we want to create manual FE for: */
	clear	
		input str40 files_to_FE
		"sample_iso3c_year_pop_den__allvars2"
		"adm1_oecd_ntl_grp"
		end
	levelsof files_to_FE, local(files_to_FE)

/* Create manual fixed effects */

foreach file in `files_to_FE' {
    use "$input/`file'.dta", clear
	keep if year >= 2012
    if ("`file'" == "sample_iso3c_year_pop_den__allvars2") {
        local location iso3c
        local Y WDI_ppp
    }
    else if ("`file'" == "adm1_oecd_ntl_grp") {
        local location region
        local Y GRP
    }

    keep ln_`Y' `location' year ln_del_sum_pix_area iso3c
    naomit
    create_categ(`location')

/* Drop duplicates --- somehow Amazonas has duplicates??? */
    bys `location' year: gen n = _N
    drop if n>=2
    drop n 

/* Demean only year FE */
    bys `location': drop if _N==1
    bys year: drop if _N==1

/* Demean year and `location' FE */
    xtset cat_`location' year
    xtreg ln_`Y' ln_del_sum_pix_area i.year, fe

    keep if e(sample)
    bys `location': drop if _N==1
    bys year: drop if _N==1
    foreach var in ln_`Y' ln_del_sum_pix_area{
    bys `location': egen mc`var'= mean(`var')
    bys year: egen my`var'= mean(`var')
    gen md`var'=`var' -mc`var'- my`var'
	gen my_init_`var'=`var' - my`var'
    drop mc`var' my`var'
    }
	
    forvalues i=1/5 {
    qui {
    foreach var in ln_`Y' ln_del_sum_pix_area{
    bys `location': egen mc`var'= mean(md`var')
    replace md`var'=md`var' -mc`var'
    bys year: egen my`var'= mean(md`var')
    replace md`var'=md`var' -my`var'
    drop mc`var' my`var'
    }
    }
    }
    regress mdln_`Y' mdln_del_sum_pix_area
    regress my_init_ln_`Y' my_init_ln_del_sum_pix_area

	save "$input/`file'_FE.dta", replace
}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	