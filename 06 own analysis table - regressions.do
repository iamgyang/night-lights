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

// ==========================================================================

cd "$input"

// ---------------------------------------------------------------------
// Own Analysis
// ---------------------------------------------------------------------

quietly capture program drop naomit
program naomit
	foreach var of varlist _all {
		drop if missing(`var')
	}
	end




foreach i in output_interaction {
	noisily capture erase "`i'.xls"
	noisily capture erase "`i'.txt"
}

local output_file "output_interaction.xls"

use "clean_validation_base.dta", clear

gen neg_growth = g_ln_WDI < 0
label variable neg_growth "GDP growth was negative"

foreach light_var in g_ln_sum_pix_area g_ln_del_sum_pix_area g_ln_sum_light_dmsp_div_area {
	regress g_ln_WDI `light_var', robust
	outreg2 using "`output_file'", append label dec(3) bdec(3)
}

keep g_ln_sum_light_dmsp_div_area g_ln_WDI iso3c year
naomit


keep g_ln_sum_pix_area g_ln_del_sum_pix_area iso3c year
br if g_ln_sum_pix_area == . & g_ln_del_sum_pix_area != .



##i.neg_growth









































