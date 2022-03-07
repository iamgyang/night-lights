# Create graphs for presentation

# Note: I had to do this in R, because otherwise in STATA it would take several
# days to complete.

rm(list = ls()) # clear the workspace
# Options: ----------------------------------------------------------------

# debugging
options(error = browser)
options(error = NULL)

# disable data.table auto-indexing (causes errors w/ dplyr functions)
options(datatable.auto.index = FALSE)

# Directories -------------------------------------------------------------

# You will have to edit this to be your own computer's working directories:
user <- Sys.info()["user"]
root_dir <-
  paste0("C:/Users/", user, "/Dropbox/CGD GlobalSat/HF_measures/")
input_dir <- paste0(root_dir, "input")
output_dir <- paste0(root_dir, "output")
code_dir <- paste0(root_dir, "code")
raw_dir <-
  paste0("C:/Users/", user, "/Dropbox/CGD GlobalSat/raw-data/")
setwd(input_dir)

# Packages ---------------------------------------------------------------
list.of.packages <-
  c(
    "data.table",
    "dplyr",
    "stringdist",
    "countrycode",
    "ggplot2",
    "ggthemes",
    "readxl",
    "tidyr",
    "glue",
    "fst",
    "readstata13"
  )

new.packages <-
  list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages))
  install.packages(new.packages, dependencies = TRUE)
for (package in list.of.packages) {
  library(eval((package)), character.only = TRUE)
}

# set GGPLOT default theme:
theme_set(theme_clean() + theme(plot.background = element_rect(color = "white")))

# load personal functions
source(paste0(
  "C:/Users/",
  user,
  "/Dropbox/Coding_General/personal.functions.R"
))


###########################################################################
# THIS IS WHERE THE ACTUAL CODE BEGINS
###########################################################################

make_graph <- function(data_f, x,y,xlab, ylab,filename){
  plot <- ggplot(data_f, 
                 aes(
                   x = eval(as.name(x)),
                   y = eval(as.name(y)))) +
    geom_point() +
    my_custom_theme +
    geom_smooth(
      method = 'lm',
      se = F,
      size = 0.5,
      colour = 'red'
    ) +
    labs(x = xlab, 
         y = ylab)
  
  ggsave(glue("{filename}.png"), plot, width = 8, height = 6)
}

glob <- readstata13::read.dta13("sample_iso3c_year_pop_den__allvars2_FE.dta")
glob <- as.data.table(glob)
oecd <- readstata13::read.dta13("adm1_oecd_ntl_grp_FE.dta")
oecd <- as.data.table(oecd)

# checks Global:
feols(ln_WDI_ppp ~ ln_del_sum_pix_area | as.factor(year), data = glob)
feols(ln_WDI_ppp ~ ln_del_sum_pix_area |
        as.factor(year) + iso3c, data = glob)
lm(mdln_WDI_ppp ~ mdln_del_sum_pix_area, data = glob)
lm(my_init_ln_WDI_ppp ~ my_init_ln_del_sum_pix_area, data = glob)

# checks OECD:
feols(ln_GRP ~ ln_del_sum_pix_area | as.factor(year), data = oecd)
feols(ln_GRP ~ ln_del_sum_pix_area |
        as.factor(year) + region, data = oecd)
lm(mdln_GRP ~ mdln_del_sum_pix_area, data = oecd)
lm(my_init_ln_GRP ~ my_init_ln_del_sum_pix_area, data = oecd)

# EU countries:
EU <- c(
  "Austria",
  "Belgium",
  "Bulgaria",
  "Croatia",
  "Republic of Cyprus",
  "Czech Republic",
  "Denmark",
  "Estonia",
  "Finland",
  "France",
  "Germany",
  "Greece",
  "Hungary",
  "Ireland",
  "Italy",
  "Latvia",
  "Lithuania",
  "Luxembourg",
  "Malta",
  "Netherlands",
  "Poland",
  "Portugal",
  "Romania",
  "Slovakia",
  "Slovenia",
  "Spain",
  "Sweden"
)

# Make graphs -------------------------------------------

# global lights to GDP
make_graph(glob, "ln_del_sum_pix_area", "ln_WDI_ppp", "Log(Lights/Area)", "Log(GDP, PPP)", "global_country_no_FE")
make_graph(glob, "my_init_ln_del_sum_pix_area", "my_init_ln_WDI_ppp", "Log(Lights/Area) - year FE", "Log(GDP, PPP) - year FE", "global_country_yr_FE")
make_graph(glob, "mdln_del_sum_pix_area", "mdln_WDI_ppp", "Log(Lights/Area) - year & country FE", "Log(GDP, PPP) - year & country FE", "global_country_yr_iso_FE")

# do the same for OECD
make_graph(oecd, "ln_del_sum_pix_area", "ln_GRP", "Log(Lights/Area)", "Log(GRP, LCU)", "oecd_region_no_FE")
make_graph(oecd, "my_init_ln_del_sum_pix_area", "my_init_ln_GRP", "Log(Lights/Area) - year FE", "Log(GRP, LCU) - year FE", "oecd_region_yr_FE")
make_graph(oecd, "mdln_del_sum_pix_area", "mdln_GRP", "Log(Lights/Area) - year & region FE", "Log(GRP, LCU) - year & region FE", "oecd_region_yr_reg_FE")

# do the same for Europe:
euo <- oecd[iso3c%in%name2code(EU)]

make_graph(euo, "ln_del_sum_pix_area", "ln_GRP", "Log(Lights/Area)", "Log(GRP, LCU)", "euo_region_no_FE")
make_graph(euo, "my_init_ln_del_sum_pix_area", "my_init_ln_GRP", "Log(Lights/Area) - year FE", "Log(GRP, LCU) - year FE", "euo_region_yr_FE")
make_graph(euo, "mdln_del_sum_pix_area", "mdln_GRP", "Log(Lights/Area) - year & region FE", "Log(GRP, LCU) - year & region FE", "euo_region_yr_reg_FE")