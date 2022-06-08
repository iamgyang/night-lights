// use "$input/aggregated_objectID_deaths_cleaned.dta", clear
// sort objectid month year
// drop if mi(gid_1) // we we have to drop if it's not attached to a specific GID_1 region

// // collapse to ADM1 year level
// gcollapse (sum) deaths, by(year gid_1 iso3c)

// // collapse to country year level
// gcollapse 


