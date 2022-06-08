rm(list = ls()) # clear the workspace
# Options: ----------------------------------------------------------------

# debugging
options(error=browser)
options(error=NULL)

# disable data.table auto-indexing (causes errors w/ dplyr functions)
options(datatable.auto.index = FALSE)

# Directories -------------------------------------------------------------

# You will have to edit this to be your own computer's working directories:
user <- Sys.info()["user"]
root_dir <- paste0("C:/Users/", user, "/Dropbox/CGD GlobalSat/HF_measures/")
input_dir <- paste0(root_dir, "input")
output_dir <- paste0(root_dir, "output")
code_dir <- paste0(root_dir, "code")
raw_dir <- paste0("C:/Users/", user, "/Dropbox/CGD GlobalSat/raw_data/")
setwd(input_dir)

# Packages ---------------------------------------------------------------
list.of.packages <- c("data.table", "dplyr", "stringdist", "countrycode", "ggplot2", "ggthemes", "readxl", "tidyr")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages)) install.packages(new.packages, dependencies = TRUE)
for (package in list.of.packages) {library(eval((package)), character.only = TRUE)}

# set GGPLOT default theme:
theme_set(theme_clean() + theme(plot.background = element_rect(color = "white")))


# source(paste0(root_dir, "code/", "helper_functions.R"))
source(paste0("C:/Users/", user, "/Dropbox/Coding_General/personal.functions.R"))

# USA ------------------------------------------------------------------

setwd(raw_dir)

# import US GRP by state
usa <- fread("National Accounts/USA/SAGDP/SAGDP1__ALL_AREAS_1997_2020.csv", 
             fill = T)

# filter for GRP
usa <- usa[Description == "Real GDP (millions of chained 2012 dollars)  "]

# filter so that we have states
usa <- usa[!(GeoName %in% c(
  "",
  "United States",
  "New England",
  "Mideast",
  "Great Lakes",
  "Plains",
  "Southeast",
  "Southwest",
  "Rocky Mountain",
  "Far West"
))]

# make sure we're in millions:
usa <- usa[Unit == "Millions of chained 2012 dollars"]

# delete unneeded rows:
usa[,c( "GeoFIPS", "Region", "TableName" , "LineCode" , 
  "IndustryClassification",  "Description" , "Unit" ):=NULL]

# check: sum of annual GRP:
usa_check1 <- as.matrix(as.data.frame(usa)[,-1])
usa_check1 <- apply(usa_check1, 2, sum)

# reshape from wide to long
usa <- melt(usa,
     id.vars = c("GeoName"),
     measure.vars = setdiff(names(usa), "GeoName"),
     variable.name = "year", 
     value.name = "GRP")

# check that the sums of annual GRP match
usa_check2 <- usa[,.(sum(GRP)), by = "year"]
usa_check <- cbind(usa_check2, usa_check1)
waitifnot(all(unlist(usa_check2[,abs(usa_check1-V1)<0.0000001])))
usa_check <- NULL; usa_check1 <- NULL; usa_check2 <- NULL

# remove missing observations
a <- nrow(usa)
usa <- na.omit(usa)
b <- nrow(usa)

# we should not have removed more than 50 observations; otherwise, complain:
waitifnot(b-a < 50)

# rename columns:
setnames(usa, "GeoName", "region")

# save
setwd(input_dir)
write.csv(usa, "USA_regional_GRP.csv", na = "", row.names = FALSE)
setwd(raw_dir)


# Philippines -------------------------------------------------------------

phl <- readxl::read_xlsx("National Accounts/PHL/GRDP_Reg_2018PSNA_2000-2020_0.xlsx")

phl <- as.data.frame(phl)

# get the specific rows of interest by extracting the 
# real GDP table from the first sheet
# Regional Accounts of the Philippines
# Unit: In thousand Philippine Pesos
# As of April 2021
# Table 1.2 Gross Regiol Domestic Product
# Annual 2000 to 2020
# At Constant 2018 Prices
phl <- phl %>%
  mutate(indic = case_when(( `Regional Accounts of the Philippines` == 
                           "Table 1.2 Gross Regional Domestic Product" ) ~ 1, 
                           ( `Regional Accounts of the Philippines` == 
                            "Table 1.3 Gross Regional Domestic Product" ) ~ 2, 
                           TRUE ~ NA_real_ )) %>% 
  tidyr::fill(indic, .direction = "down") %>% 
  dplyr::filter(indic == 1) %>% 
  as.data.frame() %>% as.data.table()

# get column names:
names(phl) <- as.character(as.numeric(unlist(phl[6,])))

# select for places where we have GRP data:
phl <- phl[!is.na(`2000`)]
names(phl)[2] <- "region"
phl[,`1`:=NULL]

# convert from wide to long
phl <- melt(phl,
            id.vars = c("region"),
            measure.vars = 
              as.character(na.omit(as.numeric(setdiff(names(phl), "region")))),
            variable.name = "year", 
            value.name = "GRP")
phl <- na.omit(phl)
phl[,c("year", "GRP"):=lapply(.SD, function(x) {as.numeric(as.character(x))}), 
                       .SDcols = c("year", "GRP")]
phl[,GRP:=GRP*1000]

# Indonesia ---------------------------------------------------------------
setwd(raw_dir)
setwd("National Accounts/IDN")

# get all GDP dataset names:
directory_file_names <-
  list.files(
    path = ".",
    pattern = NULL,
    all.files = FALSE,
    full.names = FALSE,
    recursive = FALSE,
    ignore.case = FALSE,
    include.dirs = FALSE,
    no.. = FALSE
  )
idn <- grep("Produk Domestik Regional Bruto", directory_file_names, value = T)

# import all of them
idn <- lapply(idn, function(x) {readxl::read_xlsx(x)})

idn <- lapply(idn,
              function(DT) {
                DT <- as.data.frame(DT)
                
                # get the REAL GDP values
                DT <- DT[, c(1, which(DT[1,] == "Harga Konstan 2010"):ncol(DT))]
                
                # rename the dataframe:
                names(DT) <- as.character(DT[2,])
                
                # remove NA values
                DT <- na.omit(DT)
                
                # convert from wide to long
                names(DT)[1] <- "region"
                DT <- as.data.table(DT)
                DT <- melt(
                  DT,
                  id.vars = c("region"),
                  measure.vars =
                    as.character(na.omit(as.numeric(
                      setdiff(names(DT), "region")
                    ))),
                  variable.name = "year",
                  value.name = "GRP"
                )
                DT[, c("year", "GRP") := lapply(.SD, function(x) {
                  as.numeric(as.character(x))
                }), .SDcols = c("year", "GRP")]
                DT <- na.omit(DT)
              })
idn <- rbindlist(idn)
idn <- unique(idn)



# Australia ---------------------------------------------------------------

# import data
setwd(raw_dir)
setwd("National Accounts/AUS")
aus <- readxl::read_xls("5220001_Annual_Gross_State_Product_All_States.xls", sheet = "Data1")
aus <- as.data.frame(aus)

# get the REAL GDP values (chained values; not percentages)
aus <- cbind(aus[, 1], aus[, setdiff(grep("Gross state product: Chain volume measures", names(aus), value = T), grep("Percentage", names(aus), value = T))])

# rename the first column 'year'
names(aus)[1] <- "year"

# restrict to only the values we want (as opposed to the table annotations)
aus <- aus[(which(aus$year == "Series ID")+1):nrow(aus), ]
aus <- as.data.table(aus)

# get the years of the data
aus[,year:=lubridate::year(as.Date(as.numeric(year), origin = "1899-12-30"))]

# rename to make it pretty
names(aus) <- names(aus) %>% gsub(" ;  Gross state product: Chain volume measures ;","",.)
aus <- as.data.frame(aus)

# reshape from wide to long
aus <- pivot_longer(aus, setdiff(names(aus), "year"))

# rename again to make it pretty
aus <- rename(aus, "region" = "name", 'GRP' = "value")

# finished
aus <- as.data.table(aus)

# Bind all values ---------------------------------------------------------
to_bind <- list(idn, phl, usa, aus)
names(to_bind) <- c("IDN", "PHL", "USA", "AUS")
grp_df <- rbindlist(to_bind, use.names = T, idcol = T, fill = T)
grp_df[,year:=as.numeric(as.character(year))]
setnames(grp_df, ".id", "iso3c")

setwd(input_dir)
readstata13::save.dta13(grp_df, "global_subnational_data.dta")

