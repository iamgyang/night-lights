# Packages ---------------------------------------------------------------

list.of.packages <- c(
  "car",
  "countrycode",
  "data.table",
  "dplyr",
  "foreign",
  "ggplot2",
  "ggrepel",
  "ggthemes",
  "glue",
  "graphics",
  "grDevices",
  "gvlma",
  "Hmisc",
  "imputeTS",
  "kableExtra",
  "lubridate",
  "plm",
  "purrr",
  "R.utils",
  "readxl",
  "rio",
  "scales",
  "SparseM",
  "stargazer",
  "stringr",
  "tidyr",
  "utils",
  "WDI",
  "zoo",
  "pdftools"
)

new.packages <-
  list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages))
  install.packages(new.packages, dependencies = TRUE)
for (package in list.of.packages) {
  cat(paste0(package, "\n"))
  library(eval((package)), character.only = TRUE)
}

# Directories -------------------------------------------------------------

# clear environment objects
rm(list = ls())

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

# Defaults and Functions --------------------------------------------------

# debugging
options(error = browser)
options(error = NULL)

# disable data.table auto-indexing (causes errors w/ dplyr functions)
options(datatable.auto.index = FALSE)

# set GGPLOT default theme:
theme_set(theme_clean() + theme(plot.background = element_rect(color = "white")))

source(paste0(
  "C:/Users/",
  user,
  "/Dropbox/Coding_General/personal.functions.R"
))

# Options -----------------------------------------------------------------

# do we want to load WDI data from online, or get it from the last time we loaded it?
load_new_WDI_data <- FALSE


# ================================================================================
# THIS IS WHERE THE CODE BEGINS
# ================================================================================

sal <- fread("C:/Users/user/Dropbox/CGD GlobalSat/HF_measures/input/own_test.csv")

exp_loop <- fread(
  "country	region	income
Luxembourg	Europe	HIC
Singapore	Asia	HIC
Qatar	Asia	HIC
Ireland	Europe	HIC
Isle of Man	Europe	HIC
Bermuda	Americas	HIC
Cayman Islands	Americas	HIC
Falkland Islands	Americas	HIC
Switzerland	Europe	HIC
United Arab Emirates	Asia	HIC
Norway	Europe	HIC
United States	Americas	HIC
Brunei	Asia	HIC
Gibraltar	Europe	HIC
Hong Kong	Asia	HIC
San Marino	Europe	HIC
Denmark	Europe	HIC
Netherlands	Europe	HIC
Jersey	Europe	HIC
Austria	Europe	HIC
Iceland	Europe	HIC
Germany	Europe	HIC
Sweden	Europe	HIC
Fiji	Oceania	UMIC
Armenia	Asia	UMIC
Guyana	Americas	UMIC
Sri Lanka	Asia	UMIC
Moldova	Europe	UMIC
Peru	Americas	UMIC
Comoros	Africa	LMIC
Haiti	Americas	LMIC
Syria	Asia	LMIC
Zimbabwe	Africa	LMIC
Lesotho	Africa	LMIC
Solomon Islands	Oceania	LMIC
Tanzania	Africa	LMIC
Guinea	Africa	LMIC
Liberia	Africa	LIC
Mozambique	Africa	LIC
Niger	Africa	LIC
DR Congo	Africa	LIC
Malawi	Africa	LIC
Central African Republic	Africa	LIC
Burundi	Africa	LIC
Somalia	Africa	LIC
"
)

exp_loop[, iso3c := name2code(country)]

for (i in exp_loop$iso3c) {
  plot <- ggplot(sal[iso3c %in% i],
         aes(x = WDI_ppp, y = del_sum_pix)) +
    geom_point() +
    # my_custom_theme +
    scale_color_colorblind() +
    theme_grey() +
    labs(x = "WDI PPP", y = "Sum Pixels")
  
ggsave(glue("{i}_x-wdi_y-pix.png"),
       plot,
       width = 6,
       height = 5)

       plot <- ggplot(sal[iso3c %in% i],
         aes(x = year, y = del_sum_pix)) +
    geom_point() +
    # my_custom_theme +
    scale_color_colorblind() +
    theme_grey() +
    labs(x = "year", y = "Sum Pixels")
  
ggsave(glue("{i}_x-year_y-pix.png"),
       plot,
       width = 6,
       height = 5)

       plot <- ggplot(sal[iso3c %in% i],
         aes(x = year, y = WDI_ppp)) +
    geom_point() +
    # my_custom_theme +
    scale_color_colorblind() +
    theme_grey() +
    labs(x = "year", y = "WDI PPP")
  
ggsave(glue("{i}_x-year_y-wdi.png"),
       plot,
       width = 6,
       height = 5)


}


plot <- ggplot(alice,
                 aes(x = GRP, y = del_sum_pix)) +
    geom_point() +
    # my_custom_theme +
    scale_color_colorblind() +
    theme_grey() +
    labs(x = "WDI PPP", y = "Sum Pixels") + 
    facet_wrap(~region, scales = "free")
  
  ggsave(glue("US_subnat_x-wdi_y-pix.png"),
         plot,
         width = 16,
         height = 14)
  
  plot <- ggplot(alice,
                 aes(x = year, y = del_sum_pix)) +
    geom_point() +
    # my_custom_theme +
    scale_color_colorblind() +
    theme_grey() +
    labs(x = "year", y = "Sum Pixels") +
    facet_wrap(~region, scales = "free")
  
  ggsave(glue("US_subnat_x-year_y-pix.png"),
         plot,
         width = 16,
         height = 14)
  
  plot <- ggplot(alice,
                 aes(x = year, y = GRP)) +
    geom_point() +
    # my_custom_theme +
    scale_color_colorblind() +
    theme_grey() +
    labs(x = "year", y = "WDI PPP") + 
    facet_wrap(~region, scales = "free")
  
  ggsave(glue("US_subnat_x-year_y-wdi.png"),
         plot,
         width = 16,
         height = 14)
  