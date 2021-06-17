/*
Summary:

1.	National Accounts:
	a.	Comparison with Henderson, Storeygard, and Weil:
		i.   Import the night lights dataset from CSV and append all years.
		ii.  Clean the national accounts GDP measures.
		iii. Compare the GDP measures between each other, and create a few plots.
		iv.	 Reproduce the Storygard regressions under the same specifications 
			 using the new VIIRS dataset.

	b.	City-level comparisons:
		i.	Clean city-level GDP measures
		ii.	Merge with night lights and produce regressions

2.	Household Surveys:
	a.	Get the list of variables from all the dta files in the Colombia surveys
	b.	Get the list of variables from all the dta files in the LSMS surveys

*/

// =========================================================================

// 0. Preliminaries

clear all 
set more off 
set scheme s1mono
// use up more computer memory for the sake of accurate numbers:
set type double, perm

foreach user in "`c(username)'" {
	global root "C:/Users/`user'/Dropbox/CGD GlobalSat/HF_measures"
	global code "$root/code"
}

// CHANGE THIS!! --- Do we want to install user-defined functions?
	loc install_user_defined_functions "No"

if ("`install_user_defined_functions'" == "Yes") {
	foreach i in rangestat wbopendata kountry mmerge outreg2 somersd ///
	asgen moss {
		ssc install `i'
	}
}

// =========================================================================

// 1.	National Accounts:
// 	a.	Comparison with Henderson, Storeygard, and Weil:
// 		i.   Import the night lights dataset from CSV and append all years.
			do "$code/append_base_VIIRS_ntl.do"			
			
/* 		ii.  Clean the GDP measures. 
				We have 5 GDP measures: 
				 - Oxford Economics (quarterly real LCU)
				 - IMF (quarterly nominal LCU)
				 - IMF WEO (annual real LCU)
				 - PWT (annual real PPP)
				 - WDI (annual real LCU) 
				We turn IMF into real values using the WB annual deflators and 
				then merge all these GDP measures into 1 dataset.	
*/
			do "$code/clean national GDP measures.do"
			
/* 		iii. Compare the GDP measures between each other, and create a few plots.
 			 Take a log-log plot of GDP measures. Also, calculate the standard deviation 
 			 of the difference in GDP measures and make a bargraph. 
*/
			do "$code/analysis national GDP measures.do"

/* 		iv.	 Reproduce the Storeygard regressions under the same specifications 
 			 using the new VIIRS dataset. Collapse the quarterly data, if 
             avaialble, into annual values. Night lights right now is also on
			 a month-ADM2 level, so we attempt a few ways of aggregating, by 
			 deleting negative night lights at different levels (e.g. deleted
			 negatives at a month-ADM2 level vs. country-ADM2 level, and doing
			 regressions with that separate dataset).
*/
			do "$code/storygard reproduction.do"

// 	b.	City-level comparisons:

// This is very preliminary, and we're still erroneously doing log(1+% growth)
// We're also merging city GDP w/ ADM2 night lights---

// 		i.	Clean city-level GDP measures for Indonesia
			do "$code/clean city GDP.do"
			
// 		ii.	Clean and merge with night lights
			do "$code/clean city nightlights.do"
			
// 		iii. Produce regressions
			do "$code/regression city nightlights.do"


// =========================================================================

// 2.	Household Surveys:

	/* The household surveys from Colombia and LSMS come in a ton of different 
	files and formats with different variable names and labels. So, this loops 
	through all those files and gets a table of the variables and labels so I can 
	check for any commonalities. */

// 	a.	Get the list of variables from all the dta files in the Colombia surveys
	do "$code/data list variable labels in Colombia.do"

// 	b.	Get the list of variables from all the dta files in the LSMS surveys
	do "$code/data list variable labels in LSMS.do"


// =========================================================================

// Other notes:
//
// ## Folder Structure
//
// The folders are structured like so:
//
// +---code    //--- This contains code (STATA and R). 
// |                 This is linked to github so that you 
// |                 can roll-back changes and do 
// |		         version controlling.
// |
// +---input   //--- This contains any input data as well 
// |		         as *intermediate outputs* from files in 
// |                 code. **Raw** data is stored in *folders*,
// |                 while intermediate outputs are stored in 
// |                 the overall input folder itself.
// |
// |   +---Facebook Social Connectedness
// |   +---Household Surveys
// |   |   +---Bolivia
// |   |   +---CEDLAS
// |   |   +---Chile
// |   |   +---Colombia
// |   |   +---LSMS
// |   |   +---SHRUG
// |   +---National Accounts		//--- Folder with raw data files of 
// |                                      national accounts data
// |   +---NTL Extracted Data 2012-2020    //--- Extracted Nighttime Lights 
// |                                             Data, monthly
// +---output	//--- Contains FINAL output from the code folder
// +---paper	//--- Contains anything related to the paper: 
//                    latex documents, lit review, etc.
//			
//

	
	
	
	
	
	
	
	
	
	