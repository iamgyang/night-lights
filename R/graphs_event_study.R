rm(list = ls()) # clear the workspace
# Options: ----------------------------------------------------------------

# debugging
options(error=browser)
options(error=NULL)

# disable data.table auto-indexing (causes errors w/ dplyr functions)
options(datatable.auto.index = FALSE)

# Directories -------------------------------------------------------------

# clear environment objects
rm(list = ls())

# You will have to edit this to be your own computer's working directories:
user<-Sys.info()["user"]
root_dir <- paste0("C:/Users/", user, "/Dropbox/CGD GlobalSat/HF_measures/")
input_dir <- paste0(root_dir, "input")
output_dir <- paste0(root_dir, "output")
code_dir <- paste0(root_dir, "code")

setwd(input_dir)


# Packages ---------------------------------------------------------------
{
  list.of.packages <- c(
    "base", "car", "cowplot", "dplyr", "ggplot2", "ggthemes", "graphics", "grDevices",
    "grid", "gridExtra", "gvlma", "h2o", "lubridate", "MASS", "readxl", "rio", "rms",
    "rsample", "stats", "tidyr", "utils", "zoo", "xtable", "stargazer", "data.table",
    "ggrepel", "foreign", "fst", "countrycode", "wbstats", "quantmod", "R.utils",
    "leaps", "bestglm", "dummies", "caret", "jtools", "huxtable", "haven", "ResourceSelection",
    "betareg", "quantreg", "margins", "plm", "collapse", "kableExtra", "tinytex",
    "LambertW", "scales", "stringr", "imputeTS", "shadowtext", "pdftools", "glue",
    "purrr", "OECD", "RobustLinearReg", "forcats", "WDI", "xlsx")
}

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages)) install.packages(new.packages, dependencies = TRUE)
for (package in list.of.packages) {library(eval((package)), character.only = TRUE)}

# set GGPLOT default theme:
theme_set(theme_clean() + 
            theme(plot.background = 
                    element_rect(color = "white")))


# source(paste0(root_dir, "code/", "helper_functions.R"))
source(paste0("C:/Users/", user, "/Dropbox/Coding_General/personal.functions.R"))

# Plots -------------------------------------------------------------------

df <- readstata13::read.dta13("event_study_ntl_covid.dta")

for (index_ in unique(df$index)) {}
  plot <- df %>% 
    filter(index == index_) %>% 
    ggplot(.,
                aes(x = ttt,
                    y = ln_del_sum_pix_area)) +
    geom_boxplot(aes(group = ttt)) +
    labs(x = "Months to Lockdown", y = "Log(Lights/Area)") +
    theme(axis.title.y = element_text(
      angle = 0,
      hjust = 0,
      vjust = 0.5
    )) +
    scale_x_continuous(breaks = seq(-3, 2))
  
  ggsave(filename = paste0(index_, ".pdf"), plot, width = 5, height = 5, dpi = 150)
  
  plot <- df %>% ggplot(.,
                aes(x = ttt,
                    y = g_an_ln_del_sum_pix_area)) +
    geom_boxplot(aes(group = ttt)) +
    labs(x = "Months to Lockdown", y = "Annual Difference in Log(Lights/Area)") +
    theme(axis.title.y = element_text(
      angle = 0,
      hjust = 0,
      vjust = 0.5
    )) +
    scale_x_continuous(breaks = seq(-3, 2))

  ggsave(filename = paste0(index_, ".pdf"), plot, width = 5, height = 5, dpi = 150)
  
  plot <- df %>%
    mutate(pre = ttt < 0) %>%
    group_by(iso3c, pre) %>%
    summarise(
      ln_del_sum_pix_area = mean(ln_del_sum_pix_area),
      g_an_ln_del_sum_pix_area = mean(g_an_ln_del_sum_pix_area)
    ) %>% ggplot(.,
                 aes(x = pre,
                     y = ln_del_sum_pix_area)) + geom_boxplot(aes(group = pre)) +
    labs(x = "Lockdown", y = "Log(Lights/Area)") +
    theme(axis.title.y = element_text(
      angle = 0,
      hjust = 0,
      vjust = 0.5
    ))

  ggsave(filename = paste0(index_, ".pdf"), plot, width = 5, height = 5, dpi = 150)
  
    plot <- df %>%
    mutate(pre = ttt < 0) %>%
    group_by(iso3c, pre) %>%
    summarise(
      ln_del_sum_pix_area = mean(ln_del_sum_pix_area),
      g_an_ln_del_sum_pix_area = mean(g_an_ln_del_sum_pix_area)
    ) %>% ggplot(.,
                 aes(x = pre,
                     y = g_an_ln_del_sum_pix_area)) + geom_boxplot(aes(group = pre)) +
    labs(x = "Lockdown", y = "Annual Difference in Log(Lights/Area)") +
    theme(axis.title.y = element_text(
      angle = 0,
      hjust = 0,
      vjust = 0.5
    ))
    
    ggsave(filename = paste0(index_, ".pdf"), plot, width = 5, height = 5, dpi = 150)
    
  
}