// This manually creates fixed effects for each of the variables of interest. We
// can then plot these differenced variables on a graph.

/* List out the files we want to create manual FE for: */
	clear	
		input str40 files_to_FE
		"iso3c_year_aggregation"
        "subnational_GRP", clear
		end
	levelsof files_to_FE, local(files_to_FE)

/* Create manual fixed effects */
foreach income_group in OECD Not_OECD {
foreach light_var in ln_del_sum_pix_area ln_sum_pix_bm_dec_area {
foreach file in `files_to_FE' {
    di "`light_var' `file'"
    use "$input/`file'.dta", clear
	if ("`income_group'" == "OECD") {
		keep_oecd iso3c
	} 
	else if ("`income_group'" == "Not_OECD") {
		drop_oecd iso3c
	}
	
	keep if year >= 2012
    if ("`file'" == "iso3c_year_aggregation") {
        local location iso3c
        local Y WDI_ppp
    }
    else if ("`file'" == "subnational_GRP") {
        local location region
        local Y GRP
    }

    keep ln_`Y' `location' year `light_var'  iso3c
    naomit
    create_categ(`location')

/* Drop duplicates --- somehow Amazonas has duplicates??? */
    bys `location' year: gen n = _N
    drop if n>=2
    drop n 
	di "1"
/* Demean only year FE */
    bys `location': drop if _N==1
    bys year: drop if _N==1

/* Demean year and `location' FE */
    xtset cat_`location' year
    xtreg ln_`Y' `light_var' i.year, fe
	
    keep if e(sample)
    bys `location': drop if _N==1
    bys year: drop if _N==1
    foreach var in ln_`Y' `light_var' {
    bys `location': egen mc`var'= mean(`var')
    bys year: egen my`var'= mean(`var')
    gen md`var'=`var' -mc`var'- my`var'
	gen my_init_`var'=`var' - my`var'
    drop mc`var' my`var'
    }
	di "2"
    forvalues i=1/5 {
    qui {
    foreach var in ln_`Y' `light_var' {
    bys `location': egen mc`var'= mean(md`var')
    replace md`var'=md`var' -mc`var'
    bys year: egen my`var'= mean(md`var')
    replace md`var'=md`var' -my`var'
    drop mc`var' my`var'
    }
    }
    }
    regress mdln_`Y' md`light_var'
    regress my_init_ln_`Y' my_init_`light_var'

	save "$input/`file'_`light_var'_`income_group'_FE.dta", replace
}
}
}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	