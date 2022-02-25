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

# Import night lights
setwd(input_dir)
ntl <- readstata13::read.dta13("iso3c_year_viirs_new.dta") %>% as.data.table()
ntl <- ntl[,.(light = sum(sum_pix)), by = .(year)]
lvl_2019_ntl <- ntl[year == 2019, ]$light
ntl[,value:=light / lvl_2019_ntl-1]
ntl <- ntl[year == 2019 | year == 2020]
ntl[,variable:="Light"]
ntl[,light:=NULL]

# Import electricity (obtained via WebPlotDigitizer)
graphdf <- fread("variable	value	year
GDP	0	2019
GDP	0.022454427	2021
GDP	-0.034950009	2020
Energy demand	0	2019
Energy demand	0.002781052	2021
Energy demand	-0.039702032	2020
CO2 emission	0	2019
CO2 emission	-0.000355283	2021
CO2 emission	-0.057284517	2020")

# append
graphdf <- rbindlist(list(graphdf, ntl), use.names = TRUE)

# make graph
plot <- ggplot(graphdf, aes(x = year, y = value, color=variable)) + 
  geom_line(size = 1) + 
  my_custom_theme + 
  labs(x = "Year",y = "Growth") + 
  scale_color_colorblind() + 
  scale_x_continuous(breaks = seq(2019, 2021, 1))

ggsave("lights_didnt_drop.png", plot, width = 6,height = 4)