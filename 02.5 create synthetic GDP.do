// Electricity consumption ----------------------------------------------
import delimited "$raw_data\Electricity Consumption OWID\per-capita-electricity-consumption.csv", clear

// fix ISO codes & check they match country names
drop if code == "OWID_WRL" | missing(code)
conv_ccode entity
assert code == iso | iso == ""
rename code iso3c
drop iso entity

rename percapitaelectricitykwh elec_pc
save "$input/clean_electricity_pc.dta", replace

// Tax revenue - UN Global Revenue Data ---------------------------------
import excel "$raw_data/UN Global Revenue Data/UNUWIDERGRD_2021_General_Full.xlsx", sheet("C") firstrow clear
rename AF taxes_exc_soc
rename *, lower
keep country iso currencyunitname multiplesofcurrencyunits calendaryearnearest taxes_exc_soc
rename iso iso3c
destring taxes_exc_soc, force replace
replace taxes_exc_soc = taxes_exc_soc * multiplesofcurrencyunits
drop if missing(taxes_exc_soc)

// check ISO3C codes
conv_ccode country
assert iso3c == iso | iso == ""
drop iso

// fix names
rename calendaryearnearest year

// check:
preserve
keep if iso3c == "USA" & year == 2018
assert taxes_exc_soc >= 3*10^12
assert taxes_exc_soc <= 6*10^12
restore
save "$input/clean_tax_ungrd.dta", replace

// WDI ------------------------------------------------------------------
// // GDP deflator
// NY.GDP.DEFL.ZS
// // imports
// NE.IMP.GNFS.KD
// // exports
// NE.EXP.GNFS.KD
// // total credit to private sector
// FS.AST.PRVT.GD.ZS

wbopendata, language(en – English) indicator(NY.GDP.DEFL.ZS; NE.IMP.GNFS.KD; NE.EXP.GNFS.KD; FS.AST.PRVT.GD.ZS; NY.GDP.MKTP.KN) long clear
local my_vars ny_gdp_defl_zs ne_imp_gnfs_kd ne_exp_gnfs_kd fs_ast_prvt_gd_zs ny_gdp_mktp_kn
keep countrycode year `my_vars'
rename (countrycode `my_vars') (iso3c deflator imports exports credit rgdp_lcu)

// arbitrarily take 2016 as the base year:
gen denom = deflator if year == 2016
by iso3c: egen deflator_2 = max(denom)
gen deflator_3 = deflator / deflator_2 * 100
replace deflator = deflator_3
drop deflator_* denom
assert deflator == 100 | missing(deflator) if year == 2016
save "$input/clean_wdi_synth.dta", replace

// WB population estimates (downloaded earlier) ---------------------------
use "$input/wb_pop_estimates_cleaned.dta", clear

// Merge
mmerge iso3c year using "$input/clean_electricity_pc.dta"
mmerge iso3c year using "$input/clean_tax_ungrd.dta"
mmerge iso3c year using "$input/clean_wdi_synth.dta"

drop _merge

save "$input/clean_merged_synth.dta", replace

