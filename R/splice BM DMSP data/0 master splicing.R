# Warning--if you are unable to download any of the packages here, the rest of
# the code will not work

# Packages ---------------------------------------------------------------

# clear environment objects
rm(list = ls())

list.of.packages <- c(
    "data.table",
    "xgboost",
    "verification",
    "glue",
    "ggthemes",
    "viridis",
    "ggplot2",
    "dplyr",
    "sp",
    "mlr3",
    "recipes",
    "mlr3learners",
    "paradox",
    "mlr3viz",
    "precrec",
    "mlr3tuning",
    "mlr3pipelines"
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

# You will have to edit this to be your own computer's working directories:
user <- Sys.info()["user"]
root_dir <- paste0("C:/Users/", user, "/Dropbox/CGD GlobalSat/")
input_dir <- paste0(root_dir, "HF_measures/input")
output_dir <- paste0(root_dir, "HF_measures/output")
code_dir <- paste0(root_dir, "HF_measures/code")
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
theme_set(theme_clean() +
              theme(plot.background = element_rect(color = "white"))
          # ggplot theme LATEX font:
          + theme(text = element_text(family = "LM Roman 10")))

# import personal functions:
source(glue(
    "C:/Users/{user}/Dropbox/Coding_General/personal.functions.R"
))

# # Run everything ----------------------------------------------------------
# 
# # create log directory path:
# dir.create(file.path(root_dir, "log"), showWarnings = FALSE)
# 
# closeAllConnections()
# setwd(input_dir)
# 
# # splicing
# sink(file=glue("{root_dir}log/log_mlr hyperparameter tuning 2.txt"))
# source(glue("{code_dir}/R/mlr hyperparameter tuning 2.R"), echo=TRUE, max.deparse.length=10000)
# sink()
# 
# sink(file=glue("{root_dir}log/log_splicing dmsp bm 2.txt"))
# source(glue("{code_dir}/R/splicing dmsp bm 2.R"), echo=TRUE, max.deparse.length=10000)
# sink()
# 
# setwd(input_dir)
