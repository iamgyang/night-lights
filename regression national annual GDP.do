*** Macros -----------------------------------------------------------------
	foreach user in "`c(username)'" {
		global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
		global hf_input "$root/HF_measures/input/"
		global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
	}
	
	global outreg_file_natl "$hf_input/natl_reg_1.xls"

clear all
set more off 

*** Import PWT -------------------------------------------------------------

