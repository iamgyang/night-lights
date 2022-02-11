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
setwd(input_dir)

# Packages ---------------------------------------------------------------
list.of.packages <- c("data.table", "dplyr", "stringdist", "countrycode", "ggplot2", "ggthemes")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages)) install.packages(new.packages, dependencies = TRUE)
for (package in list.of.packages) {library(eval((package)), character.only = TRUE)}

# set GGPLOT default theme:
theme_set(theme_clean() + 
            theme(plot.background = element_rect(color = "white")))


# source(paste0(root_dir, "code/", "helper_functions.R"))
source(paste0("C:/Users/", user, "/Dropbox/Coding_General/personal.functions.R"))

# -------------------------------------------------------------------------

# import data
setwd(input_dir)
a_df <- readstata13::read.dta13("NTL_VIIRS_appended_cleaned_all.dta") %>% as.data.table()
b_df <-
  fread(
    paste0(
      "C:/Users/",
      user,
      "/Dropbox/CGD GlobalSat/raw-data/EU regional GDP/NUTS2_labeled_clean.csv"
    )
  ) %>% as.data.table()

# make NTL data at an ADM1 level:
a_df <- a_df[,.(del_sum_pix = sum(del_sum_pix, na.rm = T), 
                del_sum_area = sum(del_sum_area, na.rm = T)),by = .(name_1, year, month, iso3c)]

# Get a fuzzy match between the NUTS region names and the NTL VIIRS ADM2 names:
a <- a_df$name_1 %>% unique()
b <- b_df$reg_name %>% unique()

# https://stackoverflow.com/questions/26405895/how-can-i-match-fuzzy-match-strings-from-two-datasets
library(stringdist)
d <- expand.grid(a,b) # Distance matrix in long form
names(d) <- c("a_name","b_name")
d$dist <- stringdist(d$a_name,d$b_name, method="jw") # String edit distance (use your favorite function here)

# Greedy assignment heuristic (Your favorite heuristic here)
greedyAssign <- function(a,b,d){
  x <- numeric(length(a)) # assgn variable: 0 for unassigned but assignable, 
  # 1 for already assigned, -1 for unassigned and unassignable
  while(any(x==0)){
    min_d <- min(d[x==0]) # identify closest pair, arbitrarily selecting 1st if multiple pairs
    a_sel <- a[d==min_d & x==0][1] 
    b_sel <- b[d==min_d & a == a_sel & x==0][1] 
    x[a==a_sel & b == b_sel] <- 1
    x[x==0 & (a==a_sel|b==b_sel)] <- -1
  }
  cbind(a=a[x==1],b=b[x==1],d=d[x==1])
}
data.frame(greedyAssign(as.character(d$a_name),as.character(d$b_name),d$dist))
d <- as.data.table(d)
d[,min_dist:=min(dist,na.rm = T),by = a_name]
d <- d[dist==min_dist]
d[,min_dist:=min(dist,na.rm = T),by = b_name]
d <- d[dist==min_dist]
d <- d[dist<=0.11111112]

# merge back in the new VIIRS ADM2 levels for the NUTS code
b_df <- merge(b_df, d[,.(name_1 = a_name, reg_name = b_name)], by = "reg_name", all = FALSE)
b_df <- b_df[name_1!=""]
setnames(b_df, "name","year")
setnames(b_df, "value","gdp")
j_df <- merge(b_df, a_df[,.(name_1, iso3c, del_sum_pix, del_sum_area, year, month)], by = c("name_1", "year"))

# check that the country that comes from the NUTs dataset is the same as the country that comes from the VIIRS NTL dataset:
j_df[,iso3c_NUTS:=name2code(country)]
j_df <- j_df[iso3c == iso3c_NUTS]
waitifnot(all(j_df$iso3c == j_df$iso3c_NUTS))
check_dup_id(j_df, c("reg_name", "country", "year", "month"))
j_df <- j_df[,.(gdp = mean(gdp, na.rm = T),
                del_sum_pix = sum(del_sum_pix, na.rm = T),
                del_sum_area = sum(del_sum_area, na.rm = T)), 
     by = .(reg_name, country, year)]
j_df[,del_sum_pix_area:=del_sum_pix/del_sum_area]

# export to STATA to perform regression:
setwd(input_dir)
j_df %>% readstata13::save.dta13("NUTS_validation.dta")


