// For the Columbia folder, Dropbox, IF want to rewind, do it to 11:59 AM 7/22/2021
// C:\Users\`user'\Dropbox\CGD GlobalSat\HF_measures\input\Household Surveys\Colombia


/*
Summary:

1.	National Accounts:
	a.	Comparison with Henderson, Storeygard, and Weil:
		i.   Import the night lights dataset from CSV and append all years.
		ii.  Clean the national accounts GDP measures.
		iii. Compare the GDP measures between each other, and create a few plots.
		iv.	 Reproduce the Storeygard regressions under the same specifications 
			 using the new VIIRS dataset.
		v.	 Reproduce the exact AER Storeygard output from their replication files
		
	b.	City-level comparisons:
		i.	Clean city-level GDP measures
		ii.	Merge with night lights and produce regressions
		
	c.  China subnational data:
		i.	Clean Chinese subnational data
		
	d.  Angrist, Goldberg, Jolliffe using the same data
		i.	data prep
		ii. graphs
	
	e.	Comprehensive Table of Findings		
		
2.	Household Surveys:
	a.	Get the list of variables from all the dta files in the Colombia surveys
	b.	Get the list of variables from all the dta files in the LSMS surveys
	c.	Clean Colombia dataset

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
	asgen moss reghdfe ftools {
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
 			 Take a log-log plot of GDP measures. Also, calculate the standard 
			 deviation of the difference in GDP measures and make a bargraph. 
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
			
/* 		v.	 Reproduce the exact AER Storeygard output from their replication 
			 files. May take actually going into the do file itself, as some 
			 times I had some error messages in running the first few lines.
*/
			 do "$root/input/HWS AER replication/hsw_final_tables_replication/lightspaper_replication.do"


// 	b.	City-level comparisons:

// This is very preliminary, and we're still erroneously doing log(1+% growth)
// We're also merging city GDP w/ ADM2 night lights---

// 		i.	Clean city-level GDP measures for Indonesia
			do "$code/clean city GDP.do"
			
// 		ii.	Clean and merge with night lights
			do "$code/clean city nightlights.do"
			
// 		iii. Produce regressions
			do "$code/regression city nightlights.do"

			
// c.  China subnational data:

//		i.	Clean Chinese subnational data
			do "$code/clean china.do"


// d.  Angrist, Goldberg, Jolliffe using the same data

// 		i.	data prep
			do "$code/clean population.do"
			do "$code/clean angrist.do"

// e.	Comprehensive table of findings

			do "$code/comprehensive validation table.do"

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

//	c.	Clean Colombia dataset
// 		This file does a few things: 
// 			 - converts txt files to dta files 
// 			 - appends all the colombia datasets together 
// 			 - converts spanish datasets to english
// 			 - collapses the data using the survey weights to an ADM1-month level
	do "$code/col - clean expansion factor dpto weights.do"
	do "$code/col - clean vivienda.do"
	do "$code/col - clean ocupados.do"
	do "$code/col - clean características generales.do"
	do "$code/col - merge together.do"
	do "$code/col - to english - 1.do"
	do "$code/col - collapse to adm-month.do"
	do "$code/col - to english - 2.do"
	

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

	
	
	
	
	
	
	
	
	
	