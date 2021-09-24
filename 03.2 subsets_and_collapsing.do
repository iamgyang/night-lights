// #delimit ;
// #delimit cr
use "$input/adm2_month_allvars.dta", clear

collapse (mean) sum_pix_new del_sum_pix_new del_sum_area_new stringencyindex ///
governmentresponseindex containmenthealthindex economicsupportindex ///
restr_business restr_health_monitor restr_health_resource restr_mask ///
restr_school restr_social_dist, by(iso3c year)

save "$input/iso3c_year_covid_viirs_new.dta", replace













































