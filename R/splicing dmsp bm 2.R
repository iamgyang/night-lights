# Warning--if you are unable to download any of the packages here, the rest of
# the code will not work

# Packages ---------------------------------------------------------------

# clear environment objects
rm(list = ls())

list.of.packages <- c(
  "data.table",
  "caret",
  "xgboost",
  "verification",
  "glue",
  "ggthemes",
  "ggplot2",
  "dplyr",
  "sp"
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

source(glue(
  "C:/Users/{user}/Dropbox/Coding_General/generalized_xgboost_function.R"
))

# CODE --------------------------------------------------------------------

# The goal of this code is to predict log DMSP lights via log BM lights (month)
# and lat long of ObjectID

# Load data ---------------------------------------------------------------


# + Black Marble ------------------------------------------------------------

setwd(raw_dir)
bm_ntl <- readstata13::read.dta13("Black Marble NTL/bm_adm2.dta")
bm_ntl <- as.data.table(bm_ntl)
bm_ntl <- bm_ntl[,.(OBJECTID, sum_pix_bm = BM_sumpix, pol_area, mon, year)]

# make it LOG (1+sum pixels):
bm_ntl[,ln_one_sum_pix_bm:=log(1+sum_pix_bm)]
bm_ntl[,sum_pix_bm:=NULL]

bm_ntl <- data.table::dcast(bm_ntl, OBJECTID + year + pol_area ~ mon, value.var = "ln_one_sum_pix_bm")
check_dup_id(bm_ntl, c("OBJECTID", "year"))

# + DMSP ------------------------------------------------------------------

load("DMSP ADM2/dmsp_objectid.RData")
dmsp_ntl <- bob %>% as.data.table()

# again, make it log(x) (we're predicting things, so we don't really care
# about interpretation here.)
dmsp_ntl[, ln_sum_pix_dmsp := log(sum_pix_dmsp)]
dmsp_ntl[, dmsp_pos:=as.numeric(sum_pix_dmsp>0)]
dmsp_ntl[, sum_pix_dmsp := NULL]

check_dup_id(dmsp_ntl, c("OBJECTID", "year"))

# + Lat Longs -------------------------------------------------------------

load(glue("{root_dir}intermediate_data/Aggregated Datasets/Aggregated Datasets/adm2_coords_OBJECTID/Objectid_cords.RData"))
lat_long <- data.table(OBJECTID = fl$OBJECTID,
                       lat = fl$lt,
                       long = fl$lg)
check_dup_id(lat_long, c("OBJECTID"))

setwd(input_dir)
save.image("splicing_midpoint.RData")
load("splicing_midpoint.RData")

# Merge Data & Prep -------------------------------------------------------

# merge
pvq <- merge(bm_ntl, dmsp_ntl, by = c("OBJECTID", "year"), all = T)
pvq <- merge(pvq, lat_long, by = "OBJECTID", all = T)
check_dup_id(pvq, c("OBJECTID", "year"))

# DMSP must be present:
save_pvq <- pvq %>% as.data.table()
pvq <- pvq[!is.na(dmsp_pos)]

# check that only years 2012-2013 exist in data:
waitifnot(length(setdiff(unique(pvq$year), c(2012, 2013)))==0)

setcolorder(pvq, c("OBJECTID", "year", "dmsp_pos", "ln_sum_pix_dmsp"))

# split train (2012) and test (2013):
dtrain <- pvq[year == 2012]
dtest <- pvq[year == 2013]

# Run XGBoost -----------------------------------------------------------------

# we're going to have a hurdle model -- first, run a classifier that determines
# whether DMSP is 0 or not. Then, run a nonparametric tree based model to
# determine the actual value.

classifier <- 
  xgb_wrapper(
    train_data = dtrain, 
    target_variable = "dmsp_pos", 
    excluded_vars = c("OBJECTID", "year", "ln_sum_pix_dmsp"), 
    categorical = TRUE,
    method_ = 'xgbTree'
  )

classifier <- 
  xgb_wrapper(
    train_data = dtrain, 
    target_variable = "dmsp_pos", 
    excluded_vars = c("OBJECTID", "year", "ln_sum_pix_dmsp"), 
    categorical = TRUE,
    method_ = 'xgbTree'
  )

classifier_los <- classifier[["leave out sample"]]
classifier_model <- classifier[["model"]]

continuous <- 
  xgb_wrapper(
    train_data = dtrain[dmsp_pos == 1], 
    target_variable = "ln_sum_pix_dmsp", 
    excluded_vars = c("OBJECTID", "year", "dmsp_pos"), 
    categorical = FALSE,
    method_ = 'xgbTree'
  )
continuous_los <- continuous[["leave out sample"]]
continuous_model <- continuous[["model"]]

# Graphs and Diagnostics --------------------------------------------------

# make predictions

# first, categorical prediction of 0 or 1:
dtest[, pr_pos := predict(classifier, newdata = dtest)]

# then, continuous prediction of some value:
dtest[, val_if_pos := predict(continuous, newdata = dtest)]

# final prediction is the product of the categorical (0/1 probability) with the
# continuous value OR is a conversion of the probability into 0/1s, and then
# product with the continuous value:
dtest[, pred1 := pr_pos * val_if_pos]
dtest[, pred2 := as.numeric(pr_pos>0.5) * val_if_pos]
dtest[, resid1 := target - pred1]
dtest[, resid2 := target - pred2]

# STOP HERE -------------------------------------------------------------------------

# actual vs. predicted
PLOT <- ggplot(dtest, aes(y = pred, x = target)) + 
  geom_point() + 
  my_custom_theme + 
  labs(
    y = "Predicted log(DMSP pixels)", 
    x = "Actual log(DMSP pixels)", 
    title = "Actual vs. Predicted for test sample (2013)",
    subtitle = c("Tree-based model trained on data in 2012.")
    ) + 
  geom_abline(slope = 1, intercept = 0)

ggsave("actual_v_predict_test.pdf", PLOT, width = 14, height = 14)

# residual vs. fitted plot
PLOT <- ggplot(dtest, aes(y = resid, x = pred)) + 
  geom_point() + 
  my_custom_theme + 
  labs(
    x = "Predicted log(DMSP pixels)", 
    y = "Residual", 
    title = "Residual vs. fitted plot for test sample (2013)",
    subtitle = c("Tree-based model trained on data in 2012.")
  ) + 
  geom_abline(slope = 0, intercept = 0)

ggsave("residual_v_predict_test.pdf", PLOT, width = 14, height = 14)

# RMSE:
residuals <- na.omit(dtest$resid)
print("RMSE of test sample:")
rmse_1 <- sqrt(sum(residuals^2)/length(residuals))
print(rmse_1)

# Other diagnostics -------------------------------------------------------

# Diagnostics
print(xgbmod$results)
print(xgbmod$resample)

# plot results (useful for larger tuning grids)
pdf(file = "XGB_results")
print(plot(xgbmod))
dev.off()

# cross validation RMSE:
print("cross-validated RMSE:")
print(min(xgbmod$results$RMSE))
rmse_3 <- min(xgbmod$results$RMSE)

# Actually predict values --------------------------------------------

# pessimistic RMSE:
pess_rmse <- max(rmse_1, rmse_2, rmse_3)

# calculated predicted (spliced values)
pvq[,pred_mean:=predict(xgbmod, newdata = pvq)]
pvq[,pred_lower:=pred_mean - 1.96 * pess_rmse]
pvq[,pred_upper:=pred_mean + 1.96 * pess_rmse]

# create output data.table
output <- pvq[,.(
  OBJECTID,
  year,
  sum_pix_dmsp = exp(target) - 1,
  pred_mean = exp(pred_mean) - 1,
  pred_lower = exp(pred_lower) - 1,
  pred_upper = exp(pred_upper) - 1
)]

# write to CSV
setwd(input_dir)
write.csv(output, 'spliced_dmsp_bm_adm2.csv', row.names = FALSE)
closeAllConnections()
