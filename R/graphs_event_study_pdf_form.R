---
title: "Event Study"
output: pdf_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

## R Markdown

This is an R Markdown document. Markdown is a simple formatting syntax for authoring HTML, PDF, and MS Word documents. For more details on using R Markdown see <http://rmarkdown.rstudio.com>.

When you click the **Knit** button a document will be generated that includes both content as well as the output of any embedded R code chunks within the document. You can embed an R code chunk like this:

```{r cars, echo=FALSE, results='asis'}

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


##################################
##################################
##################################
##################################
##################################
##################################
##################################
##################################
##################################

df <- readstata13::read.dta13("C:/Users/gyang/Dropbox/CGD GlobalSat/HF_measures/input/event_study_ntl_covid.dta")

df$index <- df$index %>% 
  gsub("oxcgrtstringency", "Composite Stringency Index (Oxford)",.) %>% 
  gsub("oxcgrtgovernmentresponse", "Government Response Index (Oxford)",.) %>% 
  gsub("oxcgrtcontainmenthealth", "Health Containment Index (Oxford)",.) %>% 
  gsub("oxcgrteconomicsupport", "Economic Support Index (Oxford)",.) %>% 
  gsub("cornet_business", "Business Restriction Index (Coronanet)",.) %>% 
  gsub("cornet_health_monitor", "Health Monitoring Index (Coronanet)",.) %>% 
  gsub("cornet_health_resource", "Health Resources Index (Coronanet)",.) %>% 
  gsub("cornet_mask", "Masking Index (Coronanet)",.) %>% 
  gsub("cornet_school", "School Restriction Index (Coronanet)",.) %>% 
  gsub("cornet_social_dist", "Social Distancing Index (Coronanet)",.)

  

for (index_ in unique(df$index)) {
  
    cat('\n')  
   cat("#", index_, "\n") 
   
   df %>% 
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
  
  df %>% ggplot(.,
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

  df %>%
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

  df %>%
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
    
}
```

