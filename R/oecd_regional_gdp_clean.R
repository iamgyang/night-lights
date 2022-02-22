# Note: I had to do this in R, because otherwise in STATA it would take several 
# days to complete.

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
raw_dir <- paste0("C:/Users/", user, "/Dropbox/CGD GlobalSat/raw-data/")
setwd(input_dir)

# Packages ---------------------------------------------------------------
list.of.packages <- c("data.table", "dplyr", "stringdist", "countrycode", "ggplot2", 
                      "ggthemes", "readxl", "tidyr", "glue", "fst", "readstata13")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages)) install.packages(new.packages, dependencies = TRUE)
for (package in list.of.packages) {library(eval((package)), character.only = TRUE)}

# set GGPLOT default theme:
theme_set(theme_clean() + theme(plot.background = element_rect(color = "white")))

# load personal functions
source(paste0("C:/Users/", user, "/Dropbox/Coding_General/personal.functions.R"))


###########################################################################
# THIS IS WHERE THE ACTUAL CODE BEGINS
###########################################################################

# OECD region TL3 ---------------------------------------------------------

# https://stats.oecd.org/Index.aspx?DataSetCode=REGION_ECONOM
setwd(raw_dir)
oecd_tl3 <- fread("National Accounts/oecd_region_TL3.csv")
oecd_tl3 <- oecd_tl3[Measure=="      Millions National currency, constant prices, base year 2015"]
oecd_tl3 <- oecd_tl3[`Territory Level and Typology`=="Small regions (TL3)"]
oecd_tl3 <- oecd_tl3[!grep("not regionalised", oecd_tl3$Region)]
waitifnot(all(oecd_tl3$Indicator=="Regional GDP"))
waitifnot(all(oecd_tl3$PowerCode=="Millions"))
oecd_tl3 <- oecd_tl3[,.(Value, REG_ID, Region, Year, Unit)]
setnames(oecd_tl3, names(oecd_tl3), tolower(names(oecd_tl3)))
oecd_tl3[,country_abbrev:=gsub("[[:digit:]]+", "", reg_id)]

# get the abbreviations:
oecd_abbrev <- 
  read_excel(
    "National Accounts/OECD Territorial grid and Regional typologies - September 2020.xlsx",
    sheet = "List of regions",
    na = "..",
    skip = 2
  )

# confirm that every level 3 jurisdiction has a level 2 jurisdiction above it:
oecd_abbrev <- as.data.table(oecd_abbrev)
oecd_abbrev[,TL:=as.numeric(TL)]
oecd_abbrev <- as.data.frame(oecd_abbrev)
oecd_abbrev <- oecd_abbrev %>% fill(TL,.direction = "down") %>% as.data.table()
oecd_abbrev[,diff_juris:=TL - shift(TL, n = 1, type = "lag"), by = .(ISO3)]
waitifnot(all(na.omit(oecd_abbrev$diff_juris<=1)))

# get the region just ABOVE that prior region:
oecd_abbrev <- oecd_abbrev %>% 
  mutate(reg_2 = ifelse(TL==2, `Regional name`,NA)) %>% 
  group_by(ISO3) %>% 
  fill(reg_2,.direction = "down") %>% 
  as.data.table()

oecd_tl3 <- merge(oecd_tl3, oecd_abbrev, by.x = "reg_id", by.y = "REG_ID", all.x = T)
oecd_tl3[,country:=code2name(ISO3)]
oecd_tl3[,c("region"):=NULL]
oecd_tl3[,to_match_name:=paste0(country, " -_- ", `Regional name`)]
names(oecd_tl3) <- 
  names(oecd_tl3) %>% cleanname() %>% gsub("\\.","_",.) %>% gsub("/","_",.) %>% gsub("iso3","iso3c",.)

# export
setwd(input_dir)
saveRDS(oecd_tl3, "oecd_tl3.RDS")
readstata13::save.dta13(oecd_tl3, "oecd_tl3.dta")


# OECD region TL2 ---------------------------------------------------------

setwd(raw_dir)
oecd_tl2 <- fread("National Accounts/oecd_region_TL2.csv")
oecd_tl2 <- oecd_tl2[Measure=="      Millions National currency, constant prices, base year 2015"]
oecd_tl2 <- oecd_tl2[`Territory Level and Typology`=="Large regions (TL2)"]
oecd_tl2 <- oecd_tl2[!grep("not regionalised", oecd_tl2$Region)]
waitifnot(all(oecd_tl2$Indicator=="Regional GDP"))
waitifnot(all(oecd_tl2$PowerCode=="Millions"))
oecd_tl2 <- oecd_tl2[,.(Value, REG_ID, Region, Year, Unit)]
setnames(oecd_tl2, names(oecd_tl2), tolower(names(oecd_tl2)))
oecd_tl2[,country_abbrev:=gsub("[[:digit:]]+", "", reg_id)]

# get the abbreviations:
oecd_abbrev <- 
  read_excel(
    "National Accounts/OECD Territorial grid and Regional typologies - September 2020.xlsx",
    sheet = "List of regions",
    na = "..",
    skip = 2
  )

oecd_tl2 <- merge(oecd_tl2, oecd_abbrev, by.x = "reg_id", by.y = "REG_ID", all.x = T)
oecd_tl2[,country:=code2name(ISO3)]
oecd_tl2[,c("region"):=NULL]
oecd_tl2[,to_match_name:=paste0(country, " -_- ", `Regional name`)]
names(oecd_tl2) <- 
  names(oecd_tl2) %>% cleanname() %>% gsub("\\.","_",.) %>% gsub("/","_",.) %>% gsub("iso3","iso3c",.)

# export
setwd(input_dir)
saveRDS(oecd_tl2, "oecd_tl2.RDS")
readstata13::save.dta13(oecd_tl2, "oecd_tl2.dta")

