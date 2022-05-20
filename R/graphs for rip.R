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
    "fixest",
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

make_graph <- function(data_f, x, y, xlab, ylab, filename) {
  plot <- ggplot(data_f,
                 aes(x = eval(as.name(x)),
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
         y = ylab) + 
    coord_cartesian(ylim=c(-0.3, 0.3))
  
  ggsave(glue("{filename}.png"),
         plot,
         width = 8,
         height = 6)
}

for (file in c ("subnational_GRP", "iso3c_year_aggregation")) {
  for (RHS in c("ln_del_sum_pix_area", "ln_sum_pix_bm_dec_area")) {
    for (income_group in c("OECD", "Not_OECD")) {
      if (file == "subnational_GRP") {
        LHS <- "ln_GRP"
        FE <- "region"
      }
      if (file == "iso3c_year_aggregation") {
        LHS <- "ln_WDI_ppp"
        FE <- "iso3c"
      }
      
      natl <- readstata13::read.dta13(glue("{file}_{RHS}_{income_group}_FE.dta"))
      natl <- as.data.table(natl)
      # try(natl <- rename(natl, "region" = "cat_region") %>% as.data.table())
      
      # # checks
      # feols(eval(as.name(LHS)) ~ eval(as.name(RHS)) |
      #       as.factor(year) + as.factor(eval(as.name(FE))),
      #       data = natl)
      # lm(mdln_WDI_ppp ~ mdln_del_sum_pix_area, data = natl)
      
      # lights to GDP
      make_graph(
        natl,
        glue("md{RHS}"),
        glue("md{LHS}"),
        glue("Log(Lights/Area) - year & {FE} FE"),
        glue("Log(GDP, PPP) - year & {FE} FE"),
        glue("{RHS}_{income_group}_{file}_graph")
      )
    }
  }
}
