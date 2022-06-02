// primary years of schooling (BARRO)
use "$raw_data/Barro Lee Education/LeeLee_v1.dta", clear
keep pyr year sex country
drop if sex == "MF"
conv_ccode "country"
replace iso = "COD" if country == "Congo, D.R."
replace iso = "CIV" if country == "Cote dIvoire"
check_dup_id "iso sex year"
assert(!mi(iso))
naomit
reshape wide pyr, i(iso year) j(sex, string)
rename *, lower
label variable pyrf "Primary Years of Schooling, Female"
label variable pyrm "Primary Years of Schooling, Male"
drop country
naomit
rename iso iso3c
save "$input/clean_primary_yrs_ed.dta", replace

// rule of law and democracy indicators (VDEM)
use "$raw_data/V Dem Dataset/Country_Year_V-Dem_Full+others_STATA_v12/V-Dem-CY-Full+Others-v12.dta", clear
check_dup_id "country_name year"
keep country_name year v2x_rule v2x_polyarchy v2x_libdem v2x_partipdem v2x_delibdem v2x_egaldem 
naomit
// make this democracy variable an average of the following V-Dem High-Level Democracy Indices:
// Electoral democracy index (D)	  v2x_polyarchy
// Liberal democracy index (D)	      v2x_libdem
// Participatory democracy index (D)  v2x_partipdem
// Deliberative democracy index (D)	  v2x_delibdem
// Egalitarian democracy index (D)	  v2x_egaldem
egen dem = rowmean(v2x_polyarchy v2x_libdem v2x_partipdem v2x_delibdem v2x_egaldem)
keep country_name year dem v2x_rule
label variable dem "Democracy Index (Avg. of Electoral, Liberal, Participatory, Deliberative, Egalitarian)"
check_dup_id "country_name year"
conv_ccode "country_name"
replace iso = "XKX" if country_name == "Kosovo"
replace iso = "COG" if country_name == "Republic of the Congo"
replace iso = "SWZ" if country_name == "Eswatini"
replace iso = "MKD" if country_name == "North Macedonia"
drop if country_name == "Palestine/Gaza"
drop if country_name == "Palestine/West Bank"
drop if country_name == "Palestine/British Mandate"
drop if country_name == "South Yemen"
drop if country_name == "Republic of Vietnam"
drop if country_name == "German Democratic Republic"
drop if country_name == "Somaliland"
drop if country_name == "Zanzibar"
rename iso iso3c
check_dup_id "iso3c year"
drop country_name
save "$input/clean_vdem.dta", replace

// inflation (WB from Khose)
use "$raw_data/Khose Inflation Database/annual.dta"
keep def_a country_code year country
check_dup_id "country year"
rename country_code iso3c
drop country
naomit
save "$input/khose_wb_gdp_deflator.dta", replace

// WB open data
clear
wbopendata, clear nometadata long indicator( ///
    SP.DYN.LE00.IN; ///
    SP.URB.TOTL.IN.ZS; ///
    NY.GDP.PETR.RT.ZS; ///
    SP.DYN.TFRT.IN; ///
    NE.CON.GOVT.ZS; ///
    SE.XPD.TOTL.GD.ZS; ///
    MS.MIL.XPND.GD.ZS; ///
    TT.PRI.MRCH.XD.WD; ///
    FP.CPI.TOTL.ZG; ///
) year(1950:2022)
drop if regionname == "Aggregates"
keep countrycode countryname regionname year sp_dyn_le00_in sp_urb_totl_in_zs ny_gdp_petr_rt_zs sp_dyn_tfrt_in ne_con_govt_zs se_xpd_totl_gd_zs ms_mil_xpnd_gd_zs tt_pri_mrch_xd_wd fp_cpi_totl_zg
drop if mi(regionname)
rename sp_dyn_le00_in le // Life expectancy at birth, total (years) || SP.DYN.LE00.IN
rename sp_urb_totl_in_zs urb_pop_pct // Urban population (% of total population) || SP.URB.TOTL.IN.ZS
rename ny_gdp_petr_rt_zs oil_rent // Oil rents (% of GDP) || NY.GDP.PETR.RT.ZS
rename sp_dyn_tfrt_in fert // Fertility rate, total (births per woman) || SP.DYN.TFRT.IN
rename ne_con_govt_zs gov_cons_pct // General government final consumption expenditure (% of GDP) || NE.CON.GOVT.ZS
rename se_xpd_totl_gd_zs gov_ed_pct // Government expenditure on education, total (% of GDP) || SE.XPD.TOTL.GD.ZS
rename ms_mil_xpnd_gd_zs gov_milt_pct // Military expenditure (% of GDP) || MS.MIL.XPND.GD.ZS
rename tt_pri_mrch_xd_wd tti // Net barter terms of trade index (2000 = 100) || TT.PRI.MRCH.XD.WD
rename fp_cpi_totl_zg inflation // Inflation, consumer prices (annual %) || FP.CPI.TOTL.ZG
label variable le "Life expectancy at birth, total (years)"
label variable urb_pop_pct "Urban population (% of total population)"
label variable oil_rent "Oil rents (% of GDP)"
label variable fert "Fertility rate, total (births per woman)"
label variable gov_cons_pct "General government final consumption expenditure (% of GDP)"
label variable gov_ed_pct "Government expenditure on education, total (% of GDP)"
label variable gov_milt_pct "Military expenditure (% of GDP)"
label variable tti "Net barter terms of trade index (2000 = 100)"
label variable inflation "Inflation, consumer prices (annual %)"
rename countrycode iso3c
drop countryname
sort iso3c year
save "$input/clean_wd_wdi_lots_indicators.dta", replace

.