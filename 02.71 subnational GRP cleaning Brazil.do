// get all files in directory; store in macro `dirs_toloop':
filelist , dir("$raw_data/National Accounts/BRA/Conta_da_Producao_2002_2019_xls") pattern(*.xls)
keep filename
levelsof filename, local(dirs_toloop)

// set working directory
cd "$raw_data/National Accounts/BRA/Conta_da_Producao_2002_2019_xls"

// create table to store output
clear
set obs 1
gen temp = "N/A"
tempfile base
save `base'

foreach file_name in `dirs_toloop' {

di "`file_name'"

// import file
loc sheet_name = subinstr("`file_name'", ".xls", "",.) + ".1"
di "`sheet_name'"
import excel "`file_name'", sheet("`sheet_name'") clear

// make sure each of the tables are correct (we want current prices and the price index)
keep A F E
assert E[6] == "ÍNDICE DE PREÇO       " & F[6] == "VALOR A PREÇO CORRENTE"

// isolate the table for GRP/GDP
gen C = (A == "Consumo intermediário 2002-2019")
gen D = sum(C)
drop if D == 1
drop C D
gen region = A[4]
assert A[3] == "Valor Bruto da Produção 2002-2019"
drop if F == ""
drop if A == "ANO"
destring A E F, replace

// make sure the numbers aren't destringed incorrectly
// assert F[1]>(10^4)
// assert F[1]<(10^7)

// rename things
pause

rename (A E F) (year price_index current_GRP)

// adjust to be real prices
assert mi(price_index[1])
foreach i of numlist 2/18 {
	assert !mi(price_index[`i'])
}
replace price_index = 1 if missing(price_index)

/*
right now, the price index is given as the current price divided by last year's 
price. to adjust to be real prices, we have to get the current price divided by 
2002's price. we do this through computing a cumulative product:
*/
gen grp_deflator = exp(sum(ln(price_index)))
gen GRP = current_GRP/grp_deflator
keep year region GRP
loc region = region[1]

// append to file
append using `base'
save `base', replace
}

clear
use `base'
drop if temp == "N/A"
drop temp
gen iso3c = "BRA"
gen note = "GRP values do not match official figures. Growth values do, however."

drop if strpos(region, "Região")

save "$input/brazil_subnatl_grp.dta", replace

//
// use "$input/brazil_subnatl_grp.dta", clear
//
// // validation
// gen GRP_growth = 100*(GRP / GRP[_n-1] - 1 )
// gen fx_real_usd = 5.395 if year == 2021
// replace fx_real_usd = 5.151 if year == 2020
// replace fx_real_usd = 3.946 if year == 2019
// replace fx_real_usd = 3.655 if year == 2018
// replace fx_real_usd = 3.322 if year == 2017
// replace fx_real_usd = 3.632 if year == 2016
// gen current_GRP_USD = current_GRP / fx_real_usd 
// gen current_gr_USD_BRA = current_GRP_USD / current_GRP_USD[_n-1]-1
//
// // okay, I give up. but the growth figures look roughly accurate...
// // but the GRP numbers IDK where they come from.
//
// ed
//










