// Create Synthetic GDP ---------------------------------------------------

// create table to store output
clear
set obs 1
gen income_group = "N/A"
gen ul = 99999999
gen point = 99999999
gen ll = 99999999
gen yr_start = 99999999
gen yr_end = 99999999
gen fixed_effects = "N/A"
gen WR2 = 999999999
tempfile base
save `base'

/* IIB here is India, Indonesia, and Brazil */
foreach income_group in "IIB" "OECD" { 
/* note that we can only do VIIRS for subnational because we do not have
objectID/ADM2 lvl data for DMSP */

/* Load file */
    /* India, Indonesia, Brazil */
    if ("`income_group'" == "IIB") {
    use "$input/India_Indonesia_Brazil_subnational.dta", clear
    create_categ(iso3c)
    drop if iso3c == "USA"
    }
    /* OECD */
    else if ("`income_group'" == "OECD") {
        use "$input/adm1_oecd_ntl_grp.dta", clear
        /* make sure that we indeed have all OECD countries */
        preserve
        egen check1 = _N
        keep_oecd, iso_var(iso3c)
        egen check2 = _N
        assert check1 == check2
        restore
    }

keep ln_GRP ln_del_sum_pix_area year cat_region cat_year

// define the years we do the regression on
	loc years "2013/2019"
	loc years_group `""2013" "2014" "2015" "2016" "2017" "2018" "2019""'
	rename ln_del_sum_pix_area RHS_var

// define the LHS var:
    rename ln_GRP LHS_var

// regressions
    est clear
    foreach year of numlist `years' {
        
        eststo: reghdfe LHS_var RHS_var if (year == `year' | year == `year' + 1), ///
        absorb(cat_year cat_region) vce(cluster cat_region)
            estadd local NC `e(N_clust)'
            local y= round(`e(r2_a_within)', .001)
            estadd local WR2 `y'
            
        // get the upper and lower confidence intervals and the point estimate
        preserve
        
        matrix list r(table)
        matrix test = r(table)
        foreach i in b ll ul {
            matrix `i' = test["`i'", "RHS_var"]
            loc `i' = `i'[1,1]
        }
        
        // store coefficients into my table
        clear
        set obs 1
        gen income_group = "`income_group'"
        gen point = `b'
        gen ul = `ul'
        gen ll = `ll'
        gen yr_start = `year'
        gen yr_end = `year' + 1 
        gen WR2 = `y'
        append using `base'
        save `base', replace
        
        restore
    }

// output results into LATEX

local scalar_labels `"scalars("NC Number of Countries" "WR2 Adjusted Within R-squared")"'

esttab using "$overleaf/window_`income_group'_cat_year_cat_region_subnatl.tex", replace f  ///
b(3) se(3) ar2 nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
booktabs collabels(none) mgroups(`years_group', ///
pattern(1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1) ///
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
coeflabel(RHS_var "Log Lights/Area") ///
`scalar_labels'
}

// save table results
clear
use  `base'
drop if point >9999
sort yr_start
gduplicates drop
save "$input/subnatl_window_reg_results.dta", replace






foreach income_group in "IIB" "OECD" { 

use "$input/subnatl_window_reg_results.dta", clear

keep if income_group == "`income_group'"

// get start and end years:
summarize yr_start
local x_axis_start `r(min)'
local x_axis_end `r(max)'

// graphs
set graphics off
# delimit ;
twoway (line point yr_start, lcolor(red)) 
(scatter point yr_start) (rcap ul ll yr_start, lcolor(%50) msize(4-pt)), 
ytitle("`ytitle'") ytitle(, 
orientation(horizontal)) xtitle("") 
xsize(10) ysize(5)
xlabel(`x_axis_start'(2)`x_axis_end')
legend(off)
;
# delimit cr
gr export "$overleaf/window_`income_group'_cat_year_cat_region_subnatl.png", replace
set graphics on

set graphics off
# delimit ;
twoway (line WR2 yr_start, lcolor(red)) 
(scatter WR2 yr_start) , 
ytitle("`ytitle'") ytitle(, 
orientation(horizontal)) xtitle("") 
xsize(10) ysize(5)
xlabel(`x_axis_start'(2)`x_axis_end')
legend(off)
;
# delimit cr
gr export "$overleaf/window_`income_group'_cat_year_cat_region_subnatl_WR2.png", replace
set graphics on
}



