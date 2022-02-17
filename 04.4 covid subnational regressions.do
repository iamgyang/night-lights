// load original NTL data
use "$input/NTL_VIIRS_appended_cleaned_all.dta", clear
keep objectid del_sum_pix del_sum_area year month sum_pix sum_area sum_pix_new
tempfile ntl_raw
save `ntl_raw'

// load data on subnational ADM1/ADM2 mappings
use "$raw_data/Coronanet/cvdlockwn_subnatnl_mapd.dta", clear
keep origaddress_add objectid gid_0 gid_1 gid_2
naomit
gduplicates drop
sort origaddress_add

// split into country and province
split origaddress_add, parse(-)
gen country = origaddress_add4 // gets the farthest right item
foreach i of numlist 3/1 {
	loc v = `i'+1
	replace country = origaddress_add`i' if mi(origaddress_add`v')
}
rename origaddress_add province
drop origaddress_add*
replace province = substr(province, 1, length(province) - length(country)-1)
tempfile bridge
save `bridge'

// merge with coronanet lockdowns

// import coronanet lockdown data
import delimited "$input/coronanet_subnational_lockdown.csv", clear
keep province country iso_a3 dist_index_med_est date_start
naomit
gduplicates drop
mmerge country province using `bridge'
naomit
drop _merge

// collapse year & month (not day)
gen year = substr(date_start, 1, 4)
gen month = substr(date_start, 6, 2)
gen day = substr(date_start, 9, 2)
destring year month day, replace
drop date_start
gcollapse (mean) dist_index_med_est, by(province objectid gid_0 gid_1 gid_2 year month)

// convert objectid to string variable
decode objectid, gen(objectid2)
drop objectid
rename objectid2 objectid

// create categorical variables
create_categ objectid province year month // personal function

// merge data with original NTL data and check that the polygon areas and sum pixels are correct
mmerge objectid year month using `ntl_raw'
drop if mi(dist_index_med_est)

// run a simple reghdfe of correllation between NTL and lockdown across months
gen ln_del_sum_pix_area = ln(del_sum_pix/del_sum_area)
gen del_sum_pix_area = (del_sum_pix/del_sum_area)
drop if del_sum_pix_area<=0

// make sure there are >= ___  observations for a certain province in 
// a month
sort province year month
by province: gen n = _N
keep if n >= 4

// save dataset
save "$input/covid_coronanet_regression.dta", replace
use "$input/covid_coronanet_regression.dta", clear

// label variables
label variable ln_del_sum_pix_area "Log(VIIRS Lights/Area)"
label variable dist_index_med_est "Coronanet Stringency Index"

// regression of log lights/area on index of lockdown

// country and month FE
est clear
eststo: reghdfe ln_del_sum_pix_area dist_index_med_est, absorb(cat_province cat_year cat_month) cluster(cat_province) resid
estadd local NC `e(N_clust)'
local y= round(`e(r2_a_within)', .001)
estadd local WR2 `y'

esttab using "$overleaf/covid_subnational_regressions.tex", replace f  ///
b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
label booktabs nomtitle nobaselevels collabels(none) ///
scalars("NC Number of Countries" "WR2 Adjusted Within R-squared") ///
sfmt(3)

sepscatter ln_del_sum_pix_area dist_index_med_est, ms(Oh + ) separate(gid_0) legend(size(*0.5) symxsize(*5) position(0) bplacement(nwest) region(lwidth(none)))
gr export "$overleaf/scatter_subnatl_covid_global.pdf", replace

// create a separate graph for the USA
sepscatter ln_del_sum_pix_area dist_index_med_est if gid_0 == 154, ms(Oh + ) separate(province) legend(size(*0.5) symxsize(*5) position(0) bplacement(nwest) region(lwidth(none)))
gr export "$overleaf/scatter_subnatl_usa_covid.pdf", replace

// scatter _reghdfe_resid ln_del_sum_pix_area
// sort _reghdfe_resid



// do a for loop for increments of 20 from 20 to 80 for levels of the index to create cutoff months
// create variables needed for diff in diff eventdd study
// do the eventdd command
// export the graph




