
# load back in the predicted results from python
dtest <- fread("C:/Users/user/Dropbox/CGD GlobalSat/HF_measures/input/test_data_splicing_with_predictions.csv")

if (any(names(dtest)=="ln_sum_pix_dmsp_pred_final")) {
  dtest[,sum_pix_dmsp_pred:=sinh(ln_sum_pix_dmsp_pred_final)]
}

# Graphs and Diagnostics --------------------------------------------------

dtest[, resid := log(sum_pix_dmsp) - log(sum_pix_dmsp_pred)]

# replace the log(1+x) with log(x):
dtest[,ln_sum_pix_dmsp:=log(sum_pix_dmsp)]
dtest[,ln_sum_pix_dmsp_pred:=log(sum_pix_dmsp_pred)]

invisible(lapply(names(dtest),function(.name) set(dtest, which(is.infinite(dtest[[.name]])), j = .name,value =NA)))

dtest$ln_sum_pix_dmsp_pred %>% hist(50)
dtest$ln_sum_pix_dmsp %>% hist(50)

# actual vs. predicted
PLOT <- ggplot(dtest, aes(y = ln_sum_pix_dmsp_pred, x = ln_sum_pix_dmsp)) + 
  geom_point(shape = 21) + 
  my_custom_theme + 
  labs(
    y = "Predicted Log DMSP pixels", 
    x = "Actual Log DMSP pixels", 
    title = "Actual vs. Predicted for test sample (2013)",
    subtitle = c("Tree-based model trained on data in 2012.")
    ) + 
  geom_abline(slope = 1, intercept = 0)

ggsave("actual_v_predict_test.pdf", PLOT, width = 14, height = 14)

# residual vs. fitted plot
PLOT <- ggplot(dtest, aes(y = resid, x = ln_sum_pix_dmsp_pred)) + 
  geom_point() + 
  my_custom_theme + 
  labs(
    x = "Predicted Log DMSP pixels", 
    y = "Residual", 
    title = "Residual vs. fitted plot for test sample (2013)",
    subtitle = c("Tree-based model trained on data in 2012.")
  ) + 
  geom_abline(slope = 0, intercept = 0)

ggsave("residual_v_predict_test.pdf", PLOT, width = 14, height = 14)

# regression of log growth on log growth ----------------------------------

pvq <- fread("C:/Users/user/Dropbox/CGD GlobalSat/HF_measures/input/full_data_splicing_with_predictions.csv")
if (any(names(pvq)=="ln_sum_pix_dmsp_pred")) {
  pvq[,sum_pix_dmsp_pred:=sinh(ln_sum_pix_dmsp_pred)]
}
pvq[,ln_dm_pred:= log(sum_pix_dmsp_pred)]
pvq[,ln_dm_actual:= log(sum_pix_dmsp)]
pvq[,ln_bm_actual:= Jan*Feb*Mar*Apr*May*Jun*Jul*Aug*Sep*Oct*Nov*Dec]
pvq <- pvq[order(OBJECTID, year)]
pvq[,ln_gr_dm_pred:= log(sum_pix_dmsp_pred) - shift(log(sum_pix_dmsp_pred)), by = "OBJECTID"]
pvq[,ln_gr_bm_actual:= log(ln_bm_actual) - shift(log(ln_bm_actual)), by = "OBJECTID"]
pvq[,ln_gr_dm_actual:= log(sum_pix_dmsp) - shift(log(sum_pix_dmsp)), by = "OBJECTID"]

invisible(lapply(names(pvq),function(.name) set(pvq, which(is.infinite(pvq[[.name]])), j = .name,value =NA)))

# plot a histogram!!! a is the residuals
a_ <- dtest$resid
h <- hist(a_, breaks = 100, density = 100,
          col = "grey", xlab = "Accuracy", main = "Overall") 
xfit <- seq(min(a_, na.rm = T), max(a_, na.rm = T), length = 1000) 
yfit <- dnorm(xfit, mean = mean(a_, na.rm = T), sd = sd(a_, na.rm = T)) 
yfit <- yfit * diff(h$mids[1:2]) * length(a_) 
lines(xfit, yfit, col = "black", lwd = 1)

# In summary, the following was done: Black box ML model was fit on DMSP levels
# in 2012. We leave 2013 data as a "test" set, which the model has not seen
# before, for which we can get the RMSE for our predicted measure of DMSP
# levels. Our ML model then predicts DMSP levels in 2012 and 2013 to get an
# estimate for the RMSE for this model. 

# Take log(predicted DMSP 2013) - log(predicted DMSP 2012) ~ log(actual DMSP
# 2013) - log(actual DMSP 2012). This gives us a fit with an intercept term t
# statistic ~ 20. This implies that the DMSP distribution is nonstationary. 
fit <- (lm(ln_gr_dm_actual ~ ln_gr_dm_pred, data = pvq))

# One can also fit a model of log(actual DMSP 2013) - log(actual DMSP 2012)  ~
# log(actual BM 2013) - log(actual BM 2012), in which case we again get a highly
# significant intercept term (t stat is now ~ 19). 
fit <- summary(lm(ln_gr_dm_actual ~ ln_gr_bm_actual, data = pvq))

summary(lm(ln_dm_actual ~ ln_dm_pred , data = pvq[year == 2013]))
summary(lm(ln_dm_actual ~ ln_dm_pred, data = pvq[year == 2012]))
fixest::feols(ln_dm_actual ~ ln_dm_pred | OBJECTID, data = pvq)
fixest::feols(ln_dm_actual ~ ln_bm_actual | OBJECTID, data = pvq)

save.image("2012_predict_2013.RData")