// Macros ----------------------------------------------------------------

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

// ===========================================================================

cd "$raw_data/Household Surveys/LSMS"

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
sleep 2000
dirlist, fromdir("`cdir'") pattern("*dta") save("$input/allfiles.dta") replace
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
	describe, replace clear
	gen location = "`x'"
	append using `variables'
	save `variables', replace
}
use `variables', clear

save "$input/list_of_all_lsms_variables.dta"
export excel using "$input/all_LSMS_variables.xlsx", firstrow(variables) replace


