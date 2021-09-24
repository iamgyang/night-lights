
// ================================================================
// 1. National Accounts 
// 	a. 1 country-year 
// 		i. 1 import ntl 
			do "$code/01 append_base_VIIRS_ntl.do"
// 		ii. 2 clean gdp & population 
			do "$code/02 clean national GDP measures.do"
			do "$code/03 clean_population_measures.do"
// 		iii. 3 analysis - validation 
			do "$code/04 analysis national GDP measures.do"
			do "$code/05 validation table - clean.do"
			do "$code/05 validation table - regressions.do"
// 	b. 2 city-year 
		do "$code/06 clean city GDP.do"
		do "$code/07 clean city nightlights.do" // |------ this file needs to be edited
// 	c. 3 china subnat'l accounts 
		do "$code/08 clean china.do"
// 2. Household Survey 
// 	a. 1 colombia  // |------ these files are in progress
		do "$code/09 data list variable labels in Colombia.do" 
		do "$code/10 col - clean expansion factor dpto weights.do"
		do "$code/11 col - clean vivienda.do"
		do "$code/12 col - clean ocupados.do"
		// tbd: new file: 13 col - clean caracteristicas generales
		do "$code/14 col - merge together.do"
		do "$code/15 col - to english - 1.do"
		do "$code/16 col - collapse to adm-month.do"
		do "$code/17 col - to english - 2.do"
		do "$code/999 col - todo.do"
// 	b. 2 LSMS
		do "$code/18 data list variable labels in LSMS.do"

// ================================================================

// For the Columbia folder, Dropbox, IF want to rewind, do it to 11:59 AM 7/22/2021
// C:\Users\`user'\Dropbox\CGD GlobalSat\HF_measures\input\Household Surveys\Colombia
// 		These files do a few things: 
// 			 - converts txt files to dta files 
// 			 - appends all the colombia datasets together 
// 			 - converts spanish datasets to english
// 			 - collapses the data using the survey weights to an ADM1-month level
//
// working on how to merge and select only the variables we need

