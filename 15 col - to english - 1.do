// Macros ----------------------------------------------------------------

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

// ===========================================================================

cd "$input"

// Convert everything to English ----------------------------------------------
use "cleaned_colombia_full.dta", clear

drop p6006
drop if year == 2020 | year == 2021

// decode value labeled variables to characters
ds, has(vallabel)
foreach v of varlist `r(varlist)'{
    rename `v' `v'_old
    decode `v'_old, gen(`v')
    replace `v' = string(`v'_old) if missing(`v')
}
drop *_old

order directorio secuencia_p p5000 p5010 p5020 p5030 p5040 p5050 p5070 p5080 p5090 p5090s1 p5100 p5110 p5130 p5140 p5210s1 p5210s2 p5210s3 p5210s4 p5210s5 p5210s6 p5210s7 p5210s8 p5210s9 p5210s10 p5210s11 p5210s14 p5210s15 p5210s16 p5210s17 p5210s18 p5210s19 p5210s20 p5210s21 p5210s22 p5210s24 p5220 p5220s1 p6008 p6007 p6007s1 hogar p4000 p4010 p4020 p4030s1 p4030s1a1 p4030s2 p4030s3 p4030s4 p4030s4a1 p4030s5 p4040 regis clase mes dpto fex_c_2011 area year month location_type

// convert all the variable labels manually to english
replace p5020 = "Bajamar" if p5020 == "Bajamar"
replace p5020 = "Toilet connected to sewer" if p5020 == "Inodoro conectado a alcantarillado"
replace p5020 = "Toilet connected to septic tank" if p5020 == "Inodoro conectado a pozo séptico"
replace p5020 = "Toilet without connection" if p5020 == "Inodoro sin conexión"
replace p5020 = "Latrine" if p5020 == "Letrina"
replace p5020 = "No sanitary service" if p5020 == "No tiene servicio sanitario "
replace p5030 = "Shared with people from other households" if p5030 == "Compartido con personas de otros hogares"
replace p5030 = "For the exclusive use of persons in the household" if p5030 == "De uso exclusivo de las personas del hogar"
replace p5040 = "They dispose of it in another way" if p5040 == "La eliminan de otra forma"
replace p5040 = "Burn or bury it" if p5040 == "La queman o entierran"
replace p5040 = "Dumped in a yard, lot, ditch or wasteland" if p5040 == "La tiran a un patio, lote, zanja o baldío"
replace p5040 = "Dumped in a river, stream, pipe or lagoon" if p5040 == "La tiran a un río, quebrada, caño o laguna"
replace p5040 = "By public or private collection" if p5040 == "Por recolección pública o privada"
replace p5050 = "Bottled or bagged water" if p5050 == "Agua embotellada o en bolsa"
replace p5050 = "Rain water" if p5050 == "Aguas lluvias"
replace p5050 = "Water carrier" if p5050 == "Aguatero"
replace p5050 = "Tank car" if p5050 == "Carro tanque"
replace p5050 = "From piped aqueduct" if p5050 == "De acueducto por tubería"
replace p5050 = "From other piped source" if p5050 == "De otra fuente por tubería"
replace p5050 = "From public well" if p5050 == "De pila pública"
replace p5050 = "From well with pump" if p5050 == "De pozo con bomba"
replace p5050 = "From well without pump, cistern, well or auger" if p5050 == "De pozo sin bomba, aljibe, jagüey o barreno"
replace p5050 = "From river, stream, spring or source" if p5050 == "Río, quebrada, nacimiento ó manantial"
replace p5070 = "Nowhere, no food preparation?" if p5070 == "En ninguna parte, no preparan alimentos?"
replace p5070 = "In a room used only for cooking?" if p5070 == "En un cuarto usado solo para cocinar?"
replace p5070 = "In a room used also for sleeping?" if p5070 == "En un cuarto usado también para dormir?"
replace p5070 = "In a courtyard, corridor, bower, outdoors?" if p5070 == "En un patio, corredor, enramada, al aire libre?"
replace p5070 = "In a dining room with a dishwasher?" if p5070 == "En una sala comedor con lavaplatos?"
replace p5070 = "In a dining room without a dishwasher?" if p5070 == "En una sala comedor sin lavaplatos?"
replace p5080 = "Coal" if p5080 == "Carbón mineral"
replace p5080 = "Electricity" if p5080 == "Electricidad"
replace p5080 = "Natural gas connected to public grid" if p5080 == "Gas natural conectado a red pública"
replace p5080 = "Propane gas in cylinder or pipette" if p5080 == "Gas propano en cilindro o pipeta"
replace p5080 = "Firewood, wood or charcoal" if p5080 == "Leña, madera o carbón de leña"
replace p5080 = "Waste materials" if p5080 == "Materiales de desecho"
replace p5080 = "Petroleum, gasoline, kerosene, alcohol" if p5080 == "Petróleo, gasolina, kerosene, alcohol"
replace p5090 = "In lease or sublease" if p5090 == "En arriendo o subarriendo"
replace p5090 = "In usufruct" if p5090 == "En usufructo"
replace p5090 = "Another, which one?" if p5090 == "Otra, ¿cuál?___________________"
replace p5090 = "Possession without title (de facto occupant) or collective ownership" if p5090 == "Posesión sin titulo (ocupante de hecho) ó propiedad colectiva"
replace p5090 = "Owned, being paid for" if p5090 == "Propia, la están pagando"
replace p5090 = "Owned, fully paid for" if p5090 == "Propia, totalmente pagada"
replace p4000 = "Apartment" if p4000 == "Apartamento"
replace p4000 = "House" if p4000 == "Casa"
replace p4000 = "Room(s) in tenement" if p4000 == "Cuarto (s) en inquilinato"
replace p4000 = "Room(s) in other type of structure" if p4000 == "Cuarto (s) en otro  tipo de estructura"
replace p4000 = "Other dwelling (tent, wagon, boat, cave, natural shelter, etc.)" if p4000 == "Otra vivienda (carpa, vagón, embarcación, cueva,  refugio natural, etc.)"
replace p4000 = "Indigenous housing" if p4000 == "Vivienda indígena"
replace p4010 = "Adobe or tapia pisada" if p4010 == "Adobe o tapia pisada"
replace p4010 = "Bahareque" if p4010 == "Bahareque"
replace p4010 = "Cane, matting, other plant material" if p4010 == "Caña, esterilla, otro tipo de material vegetal"
replace p4010 = "Guadua" if p4010 == "Guadua"
replace p4010 = "Brick, block, prefabricated material, stone" if p4010 == "Ladrillo, bloque, material prefabricado, piedra"
replace p4010 = "Rough lumber, board, plank" if p4010 == "Madera burda, tabla, tablón"
replace p4010 = "Polished wood" if p4010 == "Madera pulida"
replace p4010 = "Without walls" if p4010 == "Sin paredes"
replace p4010 = "Zinc, cloth, cardboard, cans, scrap, plastic" if p4010 == "Zinc, tela, cartón, latas, desechos, plástico"
replace p4020 = "Wall-to-wall carpet or rug" if p4020 == "Alfombra o tapete de pared a pared"
replace p4020 = "Tile, brick, vinisol, other synthetic materials" if p4020 == "Baldosín, ladrillo, vinisol, otros materiales sintéticos"
replace p4020 = "Cement, gravel" if p4020 == "Cemento, gravilla"
replace p4020 = "rough wood, board, plank, other" if p4020 == "Madera burda, tabla, tablón, otro vegetal"
replace p4020 = "Polished wood" if p4020 == "Madera pulida"
replace p4020 = "Marble" if p4020 == "Mármol"
replace p4020 = "Earth, sand" if p4020 == "Tierra, arena"
replace p4030s1a1 = "High" if p4030s1a1 == "Alto"
replace p4030s1a1 = "Low" if p4030s1a1 == "Bajo"
replace p4030s1a1 = "Low - low" if p4030s1a1 == "Bajo - bajo "
replace p4030s1a1 = "Pirate connection" if p4030s1a1 == "Conexión pirata"
replace p4030s1a1 = "Medium" if p4030s1a1 == "Medio"
replace p4030s1a1 = "Medium - high" if p4030s1a1 == "Medio - alto"
replace p4030s1a1 = "Medium - low" if p4030s1a1 == "Medio - bajo"
replace p4030s1a1 = "Don't know or have electric plant" if p4030s1a1 == "No sabe o cuenta con planta eléctrica"
replace p6007s1 = "Spouse" if p6007s1 == "Cónyuge"
replace p6007s1 = "Son and daughter" if p6007s1 == "Hijo e hija"
replace p6007s1 = "Other non-relative" if p6007s1 == "Otro no pariente"
replace p6007s1 = "Other relative" if p6007s1 == "Otro pariente"
replace p6007s1 = "Father or mother" if p6007s1 == "Padre o madre"

label drop _all
capture quietly drop *_new
foreach var of varlist p5210s1-p5220 p6007 p4030s1 p4030s2-p4030s4 p4030s5 p4040 {
	replace `var' = "Yes" if `var' == "Sí"
	label define `var' 0 "No" 1 "Yes"
	encode `var', gen(`var'_new) label(`var')
}

foreach var of varlist p5210s1-p5220 p6007 p4030s1 p4030s2-p4030s4 p4030s5 p4040 {
	assert `var'_new == 1 if `var' == "Yes"
	drop `var'
	rename `var'_new `var'
}

order directorio secuencia_p p5000 p5010 p5020 p5030 p5040 p5050 p5070 p5080 p5090 p5090s1 p5100 p5110 p5130 p5140 p5210s1 p5210s2 p5210s3 p5210s4 p5210s5 p5210s6 p5210s7 p5210s8 p5210s9 p5210s10 p5210s11 p5210s14 p5210s15 p5210s16 p5210s17 p5210s18 p5210s19 p5210s20 p5210s21 p5210s22 p5210s24 p5220 p5220s1 p6008 p6007 p6007s1 hogar p4000 p4010 p4020 p4030s1 p4030s1a1 p4030s2 p4030s3 p4030s4 p4030s4a1 p4030s5 p4040 regis clase mes dpto fex_c_2011 area year month location_type

save "cleaned_colombia_full_1.dta", replace
