// Grab all the Expansion factors from the folder ----------------------------

// this basically searches through the entire folder for the word "total" 
// or "Total", and then we append these files together.

if (1==0) {
	program drop _all	
}

program make_local_file_list
	args pattern_
	// get all the file names from a directory
	filelist , dir("$hf_input/Household Surveys/Colombia/") pattern(`pattern_'*)
	// norecur
	gen fullname = dirname + "/" + filename
	keep fullname
	gen ext = substr(fullname, length(fullname)-2, 3)
	keep if ext == "dta" | ext == "txt"
	end

make_local_file_list "*otal*dta"
tempfile txt_files
save `txt_files'
make_local_file_list "Total"
append using `txt_files'

// drop duplicate years
rename fullname file_name
replace file_name = subinstr(file_name, "//", "/",.)
replace file_name = subinstr(file_name, "//", "/",.)
drop if file_name == ""
// drop ext
gen x1 = strpos(file_name, "Colombia")
// get a substring within a string; we know 'Colombia' is 8 characters 
// long, so +1.
gen year = substr(file_name, x1+9, 4) 
sort year ext

by year: gen dup = _n
drop if dup >= 2

tempfile files
save "`files'"
local obs = _N

program dir_convert_2_dta
	args files_toloop_ 
	// convert the files in the directory to be DTA files:
	foreach file in "`files_toloop_'" {
		di "`file'"
		// if the file is a txt file, save it as a DTA file
		// here, dollar sign indicates the end of the string
		if (regexm("`file'", ".txt$")) {
			import delimited using "`file'", clear //bindquote(strict)
			local file = regexr("`file'", ".txt$", "")
			capture quietly gen file_name = "`file'"
			capture quietly replace file_name = "`file'"
			di "`file'.dta"
			save "`file'.dta", replace
		}

		// If the file is already a DTA file, save a column indicating the file location.
		// And, rename all the variables to be lower case.
		if (regexm("`file'", ".dta$")) {
			use "`file'", clear
			capture quietly gen file_name = "`file'"
			capture quietly replace file_name = "`file'"
			rename *, lower
			save "`file'", replace
		}
	}
end

levelsof file_name, local(files_toloop)
dir_convert_2_dta `files_toloop'

// Append all the Expansion Factor files by year: ----------------------------

make_local_file_list "*otal*dta"
keep if ext == "dta"
levelsof fullname, local(files_toloop)
clear
foreach file in `files_toloop' {
	di "`file'"
	append using "`file'", force
}

save expansion_factor.dta, replace
use expansion_factor.dta, clear

destring i_dpto, replace
replace dpto = i_dpto if dpto == .
drop i_dpto
replace file_name = subinstr(file_name, "//", "/",.)
replace file_name = subinstr(file_name, "//", "/",.)
drop if file_name == ""
gen x1 = strpos(file_name, "Colombia")
gen year = substr(file_name, x1+9, 4) 
destring year, replace
assert year == agno if agno != .
keep directorio secuencia_p orden fex_dpto_c dpto year

save expansion_factor.dta, replace











