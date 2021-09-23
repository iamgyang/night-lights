// 0. Preliminaries

clear all 
set more off
set varabbrev off
set scheme s1mono
set type double, perm

// CHANGE THIS!! --- Define your own directories:
foreach user in "`c(username)'" {
	global root "C:/Users/`user'/Dropbox/CGD GlobalSat/"
}

global code        "$root/HF_measures/code"
global input       "$root/HF_measures/input"
global output      "$root/HF_measures/output"
global raw_data    "$root/raw-data"
global ntl_input   "$root/raw-data/VIIRS NTL Extracted Data 2012-2020"

// CHANGE THIS!! --- Do we want to install user-defined functions?
loc install_user_defined_functions "No"

if ("`install_user_defined_functions'" == "Yes") {
	foreach i in rangestat wbopendata kountry mmerge outreg2 somersd ///
	asgen moss reghdfe ftools fillmissing {
		ssc install `i'
	}
}

// CHANGE THIS!! --- Do we want to import nightlights from the tabular raw data? 
// (takes a long time)
global import_nightlights "yes"

// PERSONAL PROGRAMS ----------------------------------------------

// checks if IDs are duplicated
quietly capture program drop check_dup_id
program check_dup_id
	args id_vars
	preserve
	keep `id_vars'
	sort `id_vars'
    quietly by `id_vars':  gen dup = cond(_N==1,0,_n)
	assert dup == 0
	restore
	end

// drops all missing observations
quietly capture program drop naomit
program naomit
	foreach var of varlist _all {
		drop if missing(`var')
	}
	end

// creates new variable of ISO3C country codes
quietly capture program drop conv_ccode
program conv_ccode
args country_var
	kountry `country_var', from(other) stuck
	ren(_ISO3N_) (temp)
	kountry temp, from(iso3n) to(iso3c)
	drop temp
	ren (_ISO3C_) (iso3c)
end

// create a group of logged variables
quietly capture program drop create_logvars
program create_logvars
args vars

foreach i in `vars' {
    gen ln_`i' = ln(`i')
	loc lab: variable label `i'
	di "`lab'"
	label variable ln_`i' "Log `lab'"
}
end

// ================================================================

cd "$input"

// relabel the variables that were taken means of --------------------------------

use "cleaned_colombia_full_3.dta", replace

quietly capture label variable directorio "HH ID"
quietly capture label variable secuencia_p "Sequence_p"
quietly capture label variable p5000 "Including living room-dining room, how many rooms in total does this home have?"
quietly capture label variable p5010 "How many of those rooms do the people in this household sleep in?"
quietly capture label variable p5020 "The sanitary service used by the home is:"
quietly capture label variable p5030 "The home health service is:"
quietly capture label variable p5040 "How do you mainly dispose of garbage in this home?"
quietly capture label variable p5050 "Where does this household mainly get its water for human consumption?"
quietly capture label variable p5070 "In which of the following places do the people in this world prepare food?"
quietly capture label variable p5080 "What energy or fuel do you mainly cook with in this home?"
quietly capture label variable p5090 "The dwelling occupied by this household is:"
quietly capture label variable p5090s1 "which one?"
quietly capture label variable p5100 "How much do you pay monthly for repayment fee?"
quietly capture label variable p5110 "If you wanted to sell this house, what would be the minimum market price?"
quietly capture label variable p5130 "monthly estimated rent payment"
quietly capture label variable p5140 "How much do you pay monthly for rent?"
quietly capture label variable p5210s1 "Landline service"
quietly capture label variable p5210s2 "Cable subscription television service or satellite dish"
quietly capture label variable p5210s3 "Internet service"
quietly capture label variable p5210s4 "Clothes washing machine"
quietly capture label variable p5210s5 "Fridge or refrigerator"
quietly capture label variable p5210s6 "Blender"
quietly capture label variable p5210s7 "Electric or gas stove"
quietly capture label variable p5210s8 "Electric or gas oven"
quietly capture label variable p5210s9 "Microwave oven"
quietly capture label variable p5210s10 "Electric or gas water heater or electric shower"
quietly capture label variable p5210s11 "Color television"
quietly capture label variable p5210s14 "DVD"
quietly capture label variable p5210s15 "Stereo"
quietly capture label variable p5210s16 "Computer (for home use)"
quietly capture label variable p5210s17 "Vacuum / shimmer"
quietly capture label variable p5210s18 "Air conditioner"
quietly capture label variable p5210s19 "Fan or fan"
quietly capture label variable p5210s20 "Bike"
quietly capture label variable p5210s21 "Motorcycle"
quietly capture label variable p5210s22 "Particular car"
quietly capture label variable p5210s24 "House, apartment or recreational farm"
quietly capture label variable p5220 "Does any of your member (s) have a cell phone in this household?"
quietly capture label variable p5220s1 "how many people?"
quietly capture label variable p6008 "Total number of people in the household:"
quietly capture label variable p6007 "Is the head of the household temporarily absent for work or study reasons?"
quietly capture label variable p6007s1 "Relationship with the current boss"
quietly capture label variable hogar "Home"
quietly capture label variable p4000 "Housing type"
quietly capture label variable p4010 "What is the predominant material of the exterior walls of the house?"
quietly capture label variable p4020 "What is the predominant material of the floors of the house?"
quietly capture label variable p4030s1 "Electric power"
quietly capture label variable p4030s1a1 "Stratum for rate"
quietly capture label variable p4030s2 "Natural gas connected to the public grid"
quietly capture label variable p4030s3 "Sewerage"
quietly capture label variable p4030s4 "Garbage collection"
quietly capture label variable p4030s4a1 "Times per week"
quietly capture label variable p4030s5 "Aqueduct"
quietly capture label variable p4040 "Does the aqueduct water arrive 24 hours a day during the seven days a week?"
quietly capture label variable regis "Survey log"
quietly capture label variable clase "Class"
quietly capture label variable mes "Month"
quietly capture label variable dpto "Department (ADM1)"
quietly capture label variable fex_c_2011 "Expansion factor"
quietly capture label variable area "City"
quietly capture label variable year "Year"
quietly capture label variable month "Month"
quietly capture label variable location_type "File Type"

// re-label the one-hot encoded variables --------------------------------------
label variable p5020_1  "The sanitary service used by the home is:==."
label variable p5020_2 "The sanitary service used by the home is:==Bajamar"
label variable p5020_3 "The sanitary service used by the home is:==Latrine"
label variable p5020_4 "The sanitary service used by the home is:==No sanitary service"
label variable p5020_5 "The sanitary service used by the home is:==Toilet connected to septic tank"
label variable p5020_6 "The sanitary service used by the home is:==Toilet connected to sewer"
label variable p5020_7 "The sanitary service used by the home is:==Toilet without connection"
label variable p5030_1 "The home health service is:==."
label variable p5030_2 "The home health service is:==For the exclusive use of persons in the household"
label variable p5030_3 "The home health service is:==Shared with people from other households"
label variable p5040_1 "garbage disposal?==."
label variable p5040_2 "garbage disposal?==Burn or bury it"
label variable p5040_3 "garbage disposal?==By public or private collection"
label variable p5040_4 "garbage disposal?==Dumped in a river, stream, pipe or lagoon"
label variable p5040_5 "garbage disposal?==They throw it into a yard, lot, ditch, or vacant lot"
label variable p5040_6 "garbage disposal?==They dispose of it in another way"
label variable p5050_1 "Drinking water obtained via?==."
label variable p5050_2 "Drinking water obtained via?==Bottled or bagged water"
label variable p5050_3  "Drinking water obtained via?==From other piped source"
label variable p5050_4 "Drinking water obtained via?==From piped aqueduct"
label variable p5050_5 "Drinking water obtained via?==From public well"
label variable p5050_6 "Drinking water obtained via?==From river, stream, spring or source"
label variable p5050_7 "Drinking water obtained via?==From well with pump"
label variable p5050_8 "Drinking water obtained via?==From well without pump, cistern, well or auger"
label variable p5050_9 "Drinking water obtained via?==Rain water"
label variable p5050_10 "Drinking water obtained via?==Tank car"
label variable p5050_11 "Drinking water obtained via?==Water carrier"
label variable p5070_1 "Where food prepared?=."
label variable p5070_2 "Where food prepared?==In a courtyard, corridor, bower, outdoors?"
label variable p5070_3 "Where food prepared?==In a dining room with a dishwasher?"
label variable p5070_4 "Where food prepared?==In a dining room without a dishwasher?"
label variable p5070_5 "Where food prepared?==In a room used also for sleeping?"
label variable p5070_6 "Where food prepared?==In a room used only for cooking?"
label variable p5070_7 "Where food prepared?==Nowhere, no food preparation?"
label variable p5080_1 "Cooking fuel?==."
label variable p5080_2 "Cooking fuel?==Coal"
label variable p5080_3 "Cooking fuel?==Electricity"
label variable p5080_4 "Cooking fuel?==Firewood, wood or charcoal"
label variable p5080_5 "Cooking fuel?==Natural gas connected to public grid"
label variable p5080_6 "Cooking fuel?==Petroleum, gasoline, kerosene, alcohol"
label variable p5080_7 "Cooking fuel?==Propane gas in cylinder or pipette"
label variable p5080_8 "Cooking fuel?==Waste materials"
label variable p5090_1 "Building ownership?:==."
label variable p5090_2 "Building ownership?:==Another, which one?"
label variable p5090_3 "Building ownership?:==In lease or sublease"
label variable p5090_4 "Building ownership?:==In usufruct"
label variable p5090_5 "Building ownership?:==Owned, being paid for"
label variable p5090_6 "Building ownership?:==Owned, fully paid for"
label variable p5090_7 "Building ownership?:==Possession without title (de facto occupant) or collective ownership"
label variable p6007s1_1 "Relationship with the current boss==."
label variable p6007s1_2 "Relationship with the current boss==Spouse"
label variable p6007s1_3 "Relationship with the current boss==Son and daughter"
label variable p6007s1_4 "Relationship with the current boss==Other non-relative"
label variable p6007s1_5 "Relationship with the current boss==Other relative"
label variable p6007s1_6 "Relationship with the current boss==Father or mother"
label variable p4000_1 "Housing type==."
label variable p4000_2 "Housing type==Apartment"
label variable p4000_3 "Housing type==House"
label variable p4000_4 "Housing type==Indigenous housing"
label variable p4000_5 "Housing type==Other dwelling (tent, wagon, boat, cave, natural shelter, etc.)"
label variable p4000_6 "Housing type==Room(s) in other type of structure"
label variable p4000_7 "Housing type==Room(s) in tenement"
label variable p4010_1 "What is the predominant material of the exterior walls of the house?==."
label variable p4010_2 "Material of house walls?==Adobe or tapia tread"
label variable p4010_3 "Material of house walls?==Bahareque (like adobe, clay/mud with sticks/canes)"
label variable p4010_4 "Material of house walls?==Brick, block, prefabricated material, stone"
label variable p4010_5 "Material of house walls?==Cane, matting, other plant material"
label variable p4010_6 "Material of house walls?==Guadua (thorny, clumping bamboo)"
label variable p4010_7 "Material of house walls?==Polished wood"
label variable p4010_8 "Material of house walls?==Rough lumber, board, plank"
label variable p4010_9 "Material of house walls?==Without walls"
label variable p4010_10 "Material of house walls?==Zinc, cloth, cardboard, cans, scrap, plastic"
label variable p4020_1 "Material of house floors?==."
label variable p4020_2 "Material of house floors?==Cement, gravel"
label variable p4020_3 "Material of house floors?==Earth, sand"
label variable p4020_4 "Material of house floors?==Marble"
label variable p4020_5 "Material of house floors?==Polished wood"
label variable p4020_6 "Material of house floors?==Tile, brick, vinisol, other synthetic materials"
label variable p4020_7 "Material of house floors?==Wall-to-wall carpet or rug"
label variable p4020_8 "Material of house floors?==rough wood, board, plank, other"
label variable p4030s1a1_1 "Stratum for rate==."
label variable p4030s1a1_2 "Stratum for rate==Don't know or have electric plant"
label variable p4030s1a1_3 "Stratum for rate==High"
label variable p4030s1a1_4 "Stratum for rate==Low"
label variable p4030s1a1_5 "Stratum for rate==Low - low"
label variable p4030s1a1_6 "Stratum for rate==Medium"
label variable p4030s1a1_7 "Stratum for rate==Medium - high"
label variable p4030s1a1_8 "Stratum for rate==Medium - low"
label variable p4030s1a1_9 "Stratum for rate==Pirate connection"

save "cleaned_colombia_full_4.dta", replace


// make department names ---------------------------------------------------------

use "cleaned_colombia_full_4.dta", replace

drop secuencia_p
gen department = ""
replace department =  "Antioquia" if dpto == 05
replace department =  "Atlantico" if dpto == 08
replace department =  "Bogota D.C" if dpto == 11
replace department =  "Bolivar" if dpto == 13
replace department =  "Boyaca" if dpto == 15
replace department =  "Caldas" if dpto == 17
replace department =  "Caqueta" if dpto == 18
replace department =  "Cauca" if dpto == 19
replace department =  "Cesar" if dpto == 20
replace department =  "Cordoba" if dpto == 23
replace department =  "Cundinamarca" if dpto == 25
replace department =  "Choco" if dpto == 27
replace department =  "Huila" if dpto == 41
replace department =  "La guajira" if dpto == 44
replace department =  "Magdalena" if dpto == 47
replace department =  "Meta" if dpto == 50
replace department =  "Narino" if dpto == 52
replace department =  "Norte de santander" if dpto == 54
replace department =  "Quindio" if dpto == 63
replace department =  "Risaralda" if dpto == 66
replace department =  "Santander" if dpto == 68
replace department =  "Sucre" if dpto == 70
replace department =  "Tolima" if dpto == 73
replace department =  "Valle del cauca" if dpto == 76
replace department =  "Arauca" if dpto == 81
replace department =  "Casanare" if dpto == 85
replace department =  "Putumayo" if dpto == 86
replace department =  "Archipelago department of san andres, providencia and santa Catalina" if dpto == 88
replace department =  "Amazonas" if dpto == 91

order department

// make city names ------------------------------------------------------------
gen city = ""
replace city = "Medellín" if area == 5
replace city = "Barranquilla" if area == 8
replace city = "Bogotá" if area == 11
replace city = "Cartagena" if area == 13
replace city = "Manizales" if area == 17
replace city = "Montería" if area == 23
replace city = "Villavicencio" if area == 50
replace city = "Pasto" if area == 52
replace city = "Cúcuta" if area == 54
replace city = "Bucaramanga" if area == 68
replace city = "Ibagué" if area == 73
replace city = "Cali" if area == 76
replace city = "Pereira" if area == 66

save "cleaned_colombia_full_5.dta", replace

