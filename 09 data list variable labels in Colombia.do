// 0. Preliminaries

clear all 
set more off
set varabbrev off
set scheme s1mono
set type double, perm

// CHANGE THIS!! --- Define your own directories:
foreach user in "`c(username)'" {
	global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
}

global code        "$root/HF_measures/code"
global input       "$root/HF_measures/input"
global output      "$root/HF_measures/output"
global raw_data    "$root/raw-data"
global ntl_input   "$root/raw-data/VIIRS NTL Extracted Data 2012-2020"

// CHANGE THIS!! --- Do we want to install user-defined functions?
loc install_user_defined_functions "No"

if ("`install_user_defined_functions'" == "Yes") {
	foreach i in rangestat wbopendata kountry mmerge outreg2 somersd ///
	asgen moss reghdfe ftools fillmissing {
		ssc install `i'
	}
}

// CHANGE THIS!! --- Do we want to import nightlights from the tabular raw data? 
// (takes a long time)
global import_nightlights "yes"

// PERSONAL PROGRAMS ----------------------------------------------

// checks if IDs are duplicated
quietly capture program drop check_dup_id
program check_dup_id
	args id_vars
	preserve
	keep `id_vars'
	sort `id_vars'
    quietly by `id_vars':  gen dup = cond(_N==1,0,_n)
	assert dup == 0
	restore
	end

// drops all missing observations
quietly capture program drop naomit
program naomit
	foreach var of varlist _all {
		drop if missing(`var')
	}
	end

// creates new variable of ISO3C country codes
quietly capture program drop conv_ccode
program conv_ccode
args country_var
	kountry `country_var', from(other) stuck
	ren(_ISO3N_) (temp)
	kountry temp, from(iso3n) to(iso3c)
	drop temp
	ren (_ISO3C_) (iso3c)
end

// create a group of logged variables
quietly capture program drop create_logvars
program create_logvars
args vars

foreach i in `vars' {
    gen ln_`i' = ln(`i')
	loc lab: variable label `i'
	di "`lab'"
	label variable ln_`i' "Log `lab'"
}
end

// ================================================================

cd "$raw_data/Household Surveys/Colombia"

cap program drop dirlist
program define dirlist

  syntax , fromdir(string) save(string) ///
    [pattern(string) replace append]

  // get files in "`fromdir'" using pattern
  if "`pattern'" == "" local pattern "*"
  local flist: dir "`fromdir'" files "`pattern'"

  qui {

    // initialize dataset to use
    if "`append'" != "" use "`save'", clear
    else {
      clear
      gen fname = ""
    }

    // add files to the dataset
    local i = _N
    foreach f of local flist {
      set obs `++i'
      replace fname = "`fromdir'/`f'" in `i'
    }
    save "`save'", `replace'

  }

  // recursively list directories in "`fromdir'"
  local dlist: dir "`fromdir'" dirs "*"
  foreach d of local dlist {
    dirlist , fromdir("`fromdir'/`d'") save(`save') ///
    pattern("`pattern'") append replace
  }

end

* start from the current directory
local cdir = "`c(pwd)'"

* list all files

clear
* store the directories of the dta files in a local macro:
set maxvar 32767
dirlist, fromdir("`cdir'") pattern("*dta") save("allfiles.dta") replace
qui: levelsof fname, local(dir_names_toloop)

clear
tempfile variables
			clear
			gen position = .
			gen name = ""
			gen type = ""
			gen isnumeric = .
			gen format = ""
			gen vallab = ""
			gen location = ""			
		save `variables'
clear

foreach x of local dir_names_toloop {
	use "`x'", clear
		
		local unos "á é í ó ú ñ Á É Í Ó Ú Ñ ü"
		local doss "a e i o u n a e i o u n u"

		local label ""
		forvalue i = 1/13 {   // Loop to replace accents from Spanish
			local l`i': word `i' of `=regexr("`unos'", "`:word `i' of `unos''", "`:word `i' of `doss''")'
			local label "`label' `l`i''"
		}
	
	describe, replace clear
	gen location = "`x'"
	append using `variables'
	save `variables', replace	
}
use `variables', clear


gen uniqidtot = 1
replace uniqidtot = sum(uniqidtot)

save "$input/list_of_all_colombia_variables.dta", replace
export excel using "$input/all_colombia_variables.xlsx", ///
	firstrow(variables) replace

keep uniqidtot varlab
bysort varlab: egen max_uniqidtot = min(uniqidtot)
keep if max_uniqidtot==uniqidtot
drop max_uniqidtot
sort uniqidtot
export excel using "$input/unique_all_colombia_variables.xlsx", ///
	firstrow(variables) replace


// get the consumption variables and their locations:--------------------------

import delimited "$input/colombia_bridge.csv", clear 
mmerge uniqidtot using "$input/list_of_all_colombia_variables.dta"
keep uniqidtot varlaby en name
drop if varlaby==""
tempfile second_bridge
save `second_bridge'

use "$input/list_of_all_colombia_variables.dta"
mmerge name using `second_bridge'
drop if _m ==1
drop _m
keep position name location uniqid uniqidtot en
sort location position

export excel using "$input/all_colombia_variables.xlsx", firstrow(variables) replace





























