// Macros ---------------------------------------------------------------------
foreach user in "`c(username)'" {
	global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
	global hf_input "$root/HF_measures/input/"
	global ntl_input "$hf_input/NTL Extracted Data 2012-2020/"
}
set more off 
cd "$hf_input"

foreach i in full_hender overlaps_hender full_same_sample_hender ///
full_gold overlaps_gold full_same_sample_gold {
	global `i' "$hf_input/`i'.xls"
	noisily capture erase "`i'.xls"
	noisily capture erase "`i'.txt"
}

// ------------------------------------------------------------------------
// Confirming that we have the same dataset with the original Henderson variables:

use "$hf_input/HWS AER replication/hsw_final_tables_replication/global_total_dn_uncal.dta", clear
keep year iso3v10 lndn lngdpwdilocal
drop if lndn == . | lngdpwdilocal == . 
rename (lndn lngdpwdilocal iso3v10) (lndn_orig lngdpwdilocal_orig iso3c)
tempfile original_hender
save `original_hender'

use clean_validation_base.dta, clear
keep lndn lngdpwdilocal iso3c year
drop if lndn == . | lngdpwdilocal == . 
mmerge iso3c year using `original_hender'

assert lndn == lndn_orig 
assert lngdpwdilocal == lngdpwdilocal_orig

save "vars_hender.dta", replace

// ======================================================================
// HENDERSON ============================================================
// ======================================================================
{
// full regression Henderson ------------------------------------
use clean_validation_base.dta, clear

foreach light_var in lndn ln_sum_light_dmsp_div_area ln_del_sum_pix_area ln_sum_pix_area {
foreach gdp_var in ln_WDI ln_PWT {
		di "`gdp_var' `light_var'"
		// bare henderson regression: country & year fixed effects
		quietly capture {
			reghdfe `gdp_var' `light_var', absorb(cat_iso3c cat_yr) vce(cluster cat_iso3c)
			outreg2 using "$full_hender", append ///
				label dec(3) keep (`light_var') ///
				bdec(3) addstat(Countries, e(N_clust), ///
				Adjusted Within R-squared, e(r2_a_within), ///
				Within R-squared, e(r2_within))
		}
}
}

foreach light_var in lndn ln_sum_light_dmsp_div_area ln_del_sum_pix_area ln_sum_pix_area {
foreach gdp_var in ln_WDI ln_PWT {
		// with income interaction & income dummy (maintain country-year FE)
		
		quietly capture {
		reghdfe `gdp_var' i.cat_income c.`light_var'##cat_income, ///
			absorb(cat_iso3c cat_yr) vce(cluster cat_iso3c)
		outreg2 using "$full_hender", append ///
			label dec(3) ///
			bdec(3) addstat(Countries, e(N_clust), ///
			Adjusted Within R-squared, e(r2_a_within), ///
			Within R-squared, e(r2_within))
		}
}
}

// regression on overlaps Henderson ------------------------------------
use clean_validation_base.dta, clear

keep if year == 2012 | year == 2013

foreach var in ln_sum_light_dmsp_div_area ln_del_sum_pix_area ln_sum_pix_area ln_WDI ln_PWT {
	drop if `var' == .
}

save clean_validation_overlap.dta, replace

foreach light_var in ln_sum_light_dmsp_div_area ln_del_sum_pix_area ln_sum_pix_area {
foreach gdp_var in ln_WDI ln_PWT {
		di "`gdp_var' `light_var'"
		// bare henderson regression: country & year fixed effects
		quietly capture {
			reghdfe `gdp_var' `light_var', absorb(cat_iso3c) vce(cluster cat_iso3c)
			outreg2 using "$overlaps_hender", append ///
				label dec(3) keep (`light_var') ///
				bdec(3) addstat(Countries, e(N_clust), ///
				Adjusted Within R-squared, e(r2_a_within), ///
				Within R-squared, e(r2_within))
		}
}
}

foreach light_var in ln_sum_light_dmsp_div_area ln_del_sum_pix_area ln_sum_pix_area {
foreach gdp_var in ln_WDI ln_PWT {
		// with income interaction & income dummy (maintain country-year FE)
		
		quietly capture {
		reghdfe `gdp_var' i.cat_income c.`light_var'##cat_income, ///
			absorb(cat_iso3c) vce(cluster cat_iso3c)
		outreg2 using "$overlaps_hender", append ///
			label dec(3) ///
			bdec(3) addstat(Countries, e(N_clust), ///
			Adjusted Within R-squared, e(r2_a_within), ///
			Within R-squared, e(r2_within))
		}
}
}

// full regression Henderson on same sample as overlapping ------------------------------------
use clean_validation_overlap.dta, clear
levelsof iso3c, local(countries_in_overlap)

use clean_validation_base.dta, clear
gen tokeep = "no"
foreach country_code in `countries_in_overlap' {
	replace tokeep = "yes" if iso3c == "`country_code'"
}
keep if tokeep == "yes"

// check that we have the same number of countries
local length_before: length local countries_in_overlap
levelsof iso3c, local(countries_in_overlap_after)
local length_after: length local countries_in_overlap_after
assert `length_after' == `length_before'

drop tokeep

// run regressions:
foreach light_var in lndn ln_sum_light_dmsp_div_area ln_del_sum_pix_area ln_sum_pix_area {
foreach gdp_var in ln_WDI ln_PWT {
		di "`gdp_var' `light_var'"
		// bare henderson regression: country & year fixed effects
		quietly capture {
			reghdfe `gdp_var' `light_var', absorb(cat_iso3c cat_yr) vce(cluster cat_iso3c)
			outreg2 using "$full_same_sample_hender", append ///
				label dec(3) keep (`light_var') ///
				bdec(3) addstat(Countries, e(N_clust), ///
				Adjusted Within R-squared, e(r2_a_within), ///
				Within R-squared, e(r2_within))
		}
}
}

foreach light_var in lndn ln_sum_light_dmsp_div_area ln_del_sum_pix_area ln_sum_pix_area {
foreach gdp_var in ln_WDI ln_PWT {
		// with income interaction & income dummy (maintain country-year FE)
		
		quietly capture {
		reghdfe `gdp_var' i.cat_income c.`light_var'##cat_income, ///
			absorb(cat_iso3c cat_yr) vce(cluster cat_iso3c)
		outreg2 using "$full_same_sample_hender", append ///
			label dec(3) ///
			bdec(3) addstat(Countries, e(N_clust), ///
			Adjusted Within R-squared, e(r2_a_within), ///
			Within R-squared, e(r2_within))
		}
}
}


}


// full regression Goldberg ------------------------------------
use clean_validation_base.dta, replace

// regression of mean log first difference in GDP ~ mean log first difference in lights
// regression of mean log first difference in GDP ~ mean log first difference in lights + income + lights::income

keep g_ln_gdp_gold g_ln_WDI_ppp_pc g_ln_del_sum_pix_pc g_ln_sum_pix_pc ///
g_ln_sum_light_dmsp_pc ///
mean_g_ln_lights_gold g_ln_gdp_gold g_ln_sumoflights_gold_pc ///
cat_iso3c ln_WDI_ppp_pc_1992 ln_WDI_ppp_pc_2012 cat_income1992 year

ds
local varlist `r(varlist)'
local excluded cat_iso3c cat_income`year'
local varlist : list varlist - excluded 

include "$root/HF_measures/code/copylabels.do"
collapse (mean) `varlist', by(cat_iso3c cat_income`year')
include "$root/HF_measures/code/attachlabels.do"

save "angrist_goldberg_collapsed.dta", replace
	
// define 2 datasets: 1 that is collapsed from 1992 - 2012; another collapsed from 2012-2021
foreach year in 1992 2012 {
	preserve
	
	if `year' == 1992 {
		keep if year >=1992 & year<=2012
	}
	else if `year' == 2012 {
		keep if year >=2012
	}
	
	keep g_ln_gdp_gold g_ln_WDI_ppp_pc g_ln_del_sum_pix_pc g_ln_sum_pix_pc ///
	g_ln_sum_light_dmsp_pc ///
	mean_g_ln_lights_gold g_ln_gdp_gold g_ln_sumoflights_gold_pc ///
	cat_iso3c ln_WDI_ppp_pc_1992 ln_WDI_ppp_pc_2012 cat_income`year' year
	
	ds
	local varlist `r(varlist)'
	local excluded cat_iso3c cat_income`year'
	local varlist : list varlist - excluded 

	include "$root/HF_measures/code/copylabels.do"
	collapse (mean) `varlist', by(cat_iso3c cat_income`year')
	include "$root/HF_measures/code/attachlabels.do"
	save "angrist_goldberg_`year'.dta", replace
	restore	
}

// run regressions:
foreach year in 1992 2012 {
	use angrist_goldberg_`year'.dta, clear
	foreach x_var in g_ln_del_sum_pix_pc g_ln_sum_pix_pc g_ln_sum_light_dmsp_pc ///
	mean_g_ln_lights_gold g_ln_sumoflights_gold_pc {
		foreach y_var in g_ln_WDI_ppp_pc {
			capture regress `y_var' `x_var', robust
			capture outreg2 using "$full_gold", append label dec(4)
			
// 			capture regress `y_var' `x_var' i.cat_income`year' ///
// 				c.`x_var'##cat_income`year', robust
// 			capture outreg2 using "$full_gold", append label dec(4)
		}
	}
}

// regression on overlaps Goldberg ------------------------------------
use clean_validation_base.dta, replace

keep if year == 2013

keep ln_PWT_pc_2012 g_ln_del_sum_pix_area g_ln_sum_pix_area ///
g_ln_sum_light_dmsp_div_area g_ln_PWT_pc g_ln_WDI_pc g_ln_del_sum_pix_pc ///
g_ln_sum_pix_pc g_ln_sum_light_dmsp_pc iso3c year cat_income2012

ds, has(type numeric)

foreach var of varlist `r(varlist)' {
	drop if `var' == .
}

save clean_validation_overlap_gold.dta, replace


// run regressions:
foreach base_gdp_var in ln_PWT_pc_2012 {
foreach outcome_growth_var in g_ln_del_sum_pix_area g_ln_sum_pix_area ///
g_ln_sum_light_dmsp_div_area g_ln_PWT_pc g_ln_WDI_pc g_ln_del_sum_pix_pc ///
g_ln_sum_pix_pc g_ln_sum_light_dmsp_pc {
	capture regress `outcome_growth_var' `base_gdp_var', robust
	capture outreg2 using "$overlaps_gold", append label dec(4)
	
	capture regress `outcome_growth_var' `base_gdp_var' i.cat_income2012 ///
	c.`base_gdp_var'##cat_income2012, robust
	capture outreg2 using "$overlaps_gold", append label dec(4)
}
}

// full regression Goldberg on same sample as overlapping ------------------------------------
use clean_validation_overlap_gold.dta, clear
levelsof iso3c, local(countries_in_overlap)

use clean_validation_base.dta, clear
gen tokeep = "no"
foreach country_code in `countries_in_overlap' {
	replace tokeep = "yes" if iso3c == "`country_code'"
}
keep if tokeep == "yes"

// check that we have the same number of countries
local length_before: length local countries_in_overlap
levelsof iso3c, local(countries_in_overlap_after)
local length_after: length local countries_in_overlap_after
assert `length_after' == `length_before'

drop tokeep

// define 2 datasets: 1 that is collapsed from 1992 - 2012; another collapsed from 2012-2021
foreach year in 1992 2012 {
	preserve
	
	if `year' == 1992 {
		keep if year >= 1992 & year <= 2012		
	}
	else if `year' == 2012 {
		keep if year >= 2012
	}
		
	keep g_ln_del_sum_pix_area g_ln_sum_light_dmsp_div_area g_ln_sum_pix_area ///
	g_ln_PWT_pc g_ln_WDI_pc g_ln_del_sum_pix_pc g_ln_sum_pix_pc ///
	g_ln_sum_light_dmsp_pc cat_iso3c ln_PWT_pc_1992 ln_PWT_pc_2012 cat_income`year'
	include "$root/HF_measures/code/copylabels.do"
	collapse (mean) g* ln*, by(cat_iso3c cat_income)
	include "$root/HF_measures/code/attachlabels.do"
	save "angrist_goldberg_`year'_full_overlap.dta", replace
	restore	
}

// run regressions:
foreach year in 1992 2012 {
	use "angrist_goldberg_`year'_full_overlap.dta", clear
	foreach base_gdp_var in ln_PWT_pc_`year' {
	foreach outcome_growth_var in g_ln_del_sum_pix_area g_ln_sum_pix_area ///
	g_ln_sum_light_dmsp_div_area g_ln_PWT_pc g_ln_WDI_pc g_ln_del_sum_pix_pc ///
	g_ln_sum_pix_pc g_ln_sum_light_dmsp_pc {
		capture regress `outcome_growth_var' `base_gdp_var', robust
		capture outreg2 using "$full_same_sample_gold", append label dec(4)
		
		capture regress `outcome_growth_var' `base_gdp_var' i.cat_income`year' ///
		c.`base_gdp_var'##cat_income`year', robust
		capture outreg2 using "$full_same_sample_gold", append label dec(4)
		
	}
	}	
}


// Excel macro for cleaning the finalized spreadsheet: ------------------------------------

if (1==0) {


Sub MergeExcelFiles()
    Dim fnameList, fnameCurFile As Variant
    Dim countFiles, countSheets As Integer
    Dim wksCurSheet As Worksheet
    Dim wbkCurBook, wbkSrcBook As Workbook
 
    fnameList = Application.GetOpenFilename(FileFilter:="Microsoft Excel Workbooks (*.xls;*.xlsx;*.xlsm),*.xls;*.xlsx;*.xlsm", Title:="Choose Excel files to merge", MultiSelect:=True)
 
    If (vbBoolean <> VarType(fnameList)) Then
 
        If (UBound(fnameList) > 0) Then
            countFiles = 0
            countSheets = 0
 
            Application.ScreenUpdating = False
            Application.Calculation = xlCalculationManual
 
            Set wbkCurBook = ActiveWorkbook
 
            For Each fnameCurFile In fnameList
                countFiles = countFiles + 1
 
                Set wbkSrcBook = Workbooks.Open(Filename:=fnameCurFile)
 
                For Each wksCurSheet In wbkSrcBook.Sheets
                    countSheets = countSheets + 1
                    wksCurSheet.Copy after:=wbkCurBook.Sheets(wbkCurBook.Sheets.Count)
                Next
 
                wbkSrcBook.Close SaveChanges:=False
 
            Next
 
            Application.ScreenUpdating = True
            Application.Calculation = xlCalculationAutomatic
 
            MsgBox "Processed " & countFiles & " files" & vbCrLf & "Merged " & countSheets & " worksheets", Title:="Merge Excel files"
        End If
 
    Else
        MsgBox "No files selected", Title:="Merge Excel files"
    End If
End Sub













Sub clean_hender()
'
' clean_hender Macro
'
' Keyboard Shortcut: Ctrl+d
'
    Cells.Replace What:="lndn", Replacement:= _
        "Log DMSP pixels / area (original)", LookAt:=xlPart, SearchOrder:=xlByRows _
        , MatchCase:=False, SearchFormat:=False, ReplaceFormat:=False, _
        FormulaVersion:=xlReplaceFormula2
    Cells.Replace What:="ln_sum_light_dmsp_div_area", Replacement:= _
        "Log DMSP sum of pixels / area", LookAt:=xlPart, SearchOrder:=xlByRows, _
        MatchCase:=False, SearchFormat:=False, ReplaceFormat:=False, _
        FormulaVersion:=xlReplaceFormula2
    Cells.Replace What:="ln_del_sum_pix_area", Replacement:= _
        "Log VIIRS (cleaned) pixels / area", LookAt:=xlPart, SearchOrder:=xlByRows _
        , MatchCase:=False, SearchFormat:=False, ReplaceFormat:=False, _
        FormulaVersion:=xlReplaceFormula2
    Cells.Replace What:="ln_sum_pix_area", Replacement:= _
        "Log VIIRS (raw) sum of pixels / area", LookAt:=xlPart, SearchOrder:= _
        xlByRows, MatchCase:=False, SearchFormat:=False, ReplaceFormat:=False, _
        FormulaVersion:=xlReplaceFormula2
    Cells.Replace What:="1b.cat_income", Replacement:="LIC", LookAt:=xlPart, _
        SearchOrder:=xlByRows, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False, FormulaVersion:=xlReplaceFormula2
    Cells.Replace What:="2.cat_income", Replacement:="LMIC", LookAt:=xlPart, _
        SearchOrder:=xlByRows, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False, FormulaVersion:=xlReplaceFormula2
    Cells.Replace What:="3.cat_income", Replacement:="UMIC", LookAt:=xlPart, _
        SearchOrder:=xlByRows, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False, FormulaVersion:=xlReplaceFormula2
    Cells.Replace What:="4.cat_income", Replacement:="HIC", LookAt:=xlPart, _
        SearchOrder:=xlByRows, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False, FormulaVersion:=xlReplaceFormula2
    Cells.Replace What:="#c.", Replacement:=" :: ", LookAt:=xlPart, _
        SearchOrder:=xlByRows, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False, FormulaVersion:=xlReplaceFormula2
    Cells.Replace What:="#co.", Replacement:=" :: ", LookAt:=xlPart, _
        SearchOrder:=xlByRows, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False, FormulaVersion:=xlReplaceFormula2
    ActiveWindow.SmallScroll Down:=-42
    Range("I7").Select
End Sub
}



