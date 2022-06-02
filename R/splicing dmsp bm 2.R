
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



# FINISHED IMPORTING DATA -------------------------------------------------

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

# for all values that are infinite, turn it into NA values
invisible(lapply(names(pvq),function(.name) set(pvq, which(is.infinite(pvq[[.name]])), j = .name,value =NA)))

# split train (2012) and test (2013):
dtrain <- pvq[year == 2012]
dtest <- pvq[year == 2013]

# get row number:
num_rows <- nrow(dtrain)
dtrain[,row_num:=seq(1, num_rows)]

setwd(input_dir)
save.image("merging_midpoint.RData")
load("merging_midpoint.RData")


# Run XGBoost -----------------------------------------------------------------

# we're going to have a hurdle model -- first, run a classifier that determines
# whether DMSP is 0 or not. Then, run a model that determines a numeric value given that DMSP is 1. Then, merge the two models by multiplying the probability that we obtain from one to the numeric value we obtain by the other.

set.seed(983409)
dtrain_samp <- sample_n(dtrain, 100)

classifier_model <- 
  xgb_wrapper(
    train_data = dtrain_samp, 
    target_variable = "dmsp_pos", 
    excluded_vars = c("OBJECTID", "year", "ln_sum_pix_dmsp", "row_num"), 
    categorical = TRUE,
    method_ = 'xgbTree',
    cv_num = 2,
    tune_grid_row_size = 2,
    seed_train = 940384
  )

continuous_model <- 
  xgb_wrapper(
    train_data = dtrain_samp[dmsp_pos == 1], 
    target_variable = "ln_sum_pix_dmsp", 
    excluded_vars = c("OBJECTID", "year", "dmsp_pos", "row_num"), 
    categorical = FALSE,
    method_ = 'xgbTree',
    cv_num = 2,
    tune_grid_row_size = 2,
    seed_train = 940384
  )

# Graphs and Diagnostics --------------------------------------------------

# make predictions

prediction_xgb <- function(new_data) {
  # first, categorical prediction of 0 or 1:
  prob_pos <- predict(classifier_model, new_data, type = "prob")$"Yes"
  
  # then, given that one is positive, predict the continuous value:
  value_given_pos <- predict(continuous_model, new_data, type = "raw")
  
  # final prediction is the product of the categorical (0/1 probability) with the
  # continuous value:
  return(prob_pos * value_given_pos)
}

dtest[, pred := prediction_xgb(dtest)]
dtest[, resid := ln_sum_pix_dmsp - pred]

# STOP HERE ----------------------------------------------------------------

# actual vs. predicted
PLOT <- ggplot(dtest, aes(y = pred, x = ln_sum_pix_dmsp)) + 
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


# Other diagnostics -------------------------------------------------------

for (xgbmod in list(continuous_model, classifier_model)) {
  name_xgbmod <- xgbmod$modelType
  # Diagnostics
  print(xgbmod$results)
  print(xgbmod$resample)
  
  # plot results (useful for larger tuning grids)
  pdf(file = glue("XGB_results_{name_xgbmod}.pdf"))
  print(plot(xgbmod))
  dev.off()
}

# test set RMSE:
residuals <- na.omit(dtest$resid)
residuals <- residuals[is.finite(residuals)]
print("RMSE of test sample:")
rmse_1 <- sqrt(sum(residuals^2)/length(residuals))
print(rmse_1)

# # hold out train set RMSE:
# residuals <- na.omit(dtest$resid)
# residuals <- residuals[is.finite(residuals)]
# print("RMSE of test sample:")
# rmse_1 <- sqrt(sum(residuals^2)/length(residuals))
# print(rmse_1)

# # cross validation RMSE:
# print("cross-validated RMSE:")
# print(min(xgbmod$results$RMSE))
# rmse_3 <- min(xgbmod$results$RMSE)

# Actually predict values --------------------------------------------

# pessimistic RMSE:
pess_rmse <- max(rmse_1)#, rmse_3)

# calculated predicted (spliced values)
pvq[, pred_mean := prediction_xgb(pvq)]
pvq[, pred_lower := pred_mean - 1.96 * pess_rmse]
pvq[, pred_upper := pred_mean + 1.96 * pess_rmse]

# create output data.table
output <- pvq[,.(
  OBJECTID,
  year,
  ln_sum_pix_dmsp = ln_sum_pix_dmsp,
  pred_mean = pred_mean,
  pred_lower = pred_lower,
  pred_upper = pred_upper
)]

# write to CSV
setwd(input_dir)
write.csv(output, 'spliced_dmsp_bm_adm2.csv', row.names = FALSE)
closeAllConnections()

save.image(glue("run_{as.name(as.character(Sys.Date()))}.RData"))
