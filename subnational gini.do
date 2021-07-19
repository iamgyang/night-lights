cls

// Macros -----------------------------------------------------------------
	foreach user in "`c(username)'" {
		global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
		global hf_input "$root/HF_measures/input/"
		global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
	}

	global outreg_file_natl_yr "$hf_input/natl_reg_hender_34.xls"
	global outreg_file_compare_12_13 "$hf_input/natl_reg_dmsp_7.xls"
	clear all
	set more off 
	
// Subnational Gini --------------------------------------------------------