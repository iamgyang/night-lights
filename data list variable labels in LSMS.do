// clear workspaces
cls
clear all
pause off
set more off
// use up more computer memory for the sake of accurate numbers:
set type double, perm


// ========== Macros ============
foreach user in "`c(username)'" {
		global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
		global hf_input "$root/HF_measures/input/"
		global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
}
	
cd "$input/Household Surveys/LSMS"

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
	describe, replace clear
	gen location = "`x'"
	append using `variables'
	save `variables', replace	
}
use `variables', clear

save "$input/list_of_all_lsms_variables.dta"
export excel using "$input/all_LSMS_variables.xlsx", firstrow(variables) replace


