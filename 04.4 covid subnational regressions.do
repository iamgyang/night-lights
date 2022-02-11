// load data
use "$raw_data/Coronanet/cvdlockwn_subnatnl_mapd.dta", clear

// keep variables of interest


// create categorical variables
// merge data with original NTL data and check that the polygon areas and sum pixels are correct
// run a simple reghdfe of correllation between NTL and lockdown across months
// preserve and collapse (using a mean), and run another correllation between NTL and lockdown
// do a for loop for increments of 20 from 20 to 80 for levels of the index to create cutoff months
// create variables needed for diff in diff eventdd study
// do the eventdd command
// export the graph
