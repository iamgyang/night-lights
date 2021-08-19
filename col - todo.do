// TO DO -----------------------------------------------------------------
// XX get the weightings from the email --> BUT how do we use the weightings for 
// city-level stuff?
// clean code --> more programs, less explicit
// merge in education level, age, and sex (ed can be used as an instrument)
// get income from all sources (could map the types of income)
// we're missing march - july 2020, october 2020 BECAUSE OF COVID (had to limit survey)
// find which file has income (PDF)
// ocupados
// apply same process (grep for that PDF name --> use program to append together)
// apply same checks
// then, merge w/ this file.
// education: general characteristics
// collapse (mean) `r(varlist)', by(location_type month year dpto directorio)
// ds, has(type numeric)
// where I'm confused:
// 1) 
// fex_2011 = weight = (population / sample number)
// Can I get the average segment-level estimators by taking a weighted average?
// Or, do I have to do something different?
// 2) 
// The survey says that it is not representative on a monthly level for the ADM1 
// departamento level, but rather is only represntative for a set of 24 cities.
// BUT, there is no variable that gives which city?
// make sure that we can replicate colombia's unemployment numbers
