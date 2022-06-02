
# load back in the predicted results from python
dtest <- fread("test_data_splicing_with_predictions.csv")

# Graphs and Diagnostics --------------------------------------------------

setnames(dtest, "sum_pix_dmsp_pred", "pred")
dtest[, resid := log(sum_pix_dmsp) - log(pred)]

# actual vs. predicted
PLOT <- ggplot(dtest, aes(y = log(pred), x = log(sum_pix_dmsp))) + 
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
PLOT <- ggplot(dtest, aes(y = resid, x = log(pred))) + 
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

pvq <- fread("full_data_splicing_with_predictions.csv")
pvq <- pvq[order(OBJECTID, year)]
pvq[,ln_gr_dm_pred:= log(sum_pix_dmsp_pred_mean) - shift(log(sum_pix_dmsp_pred_mean)), by = "OBJECTID"]
pvq[,ln_gr_bm_actual:= log(Dec) - shift(log(Dec)), by = "OBJECTID"]
pvq[,ln_gr_dm_actual:= log(sum_pix_dmsp) - shift(log(sum_pix_dmsp)), by = "OBJECTID"]
invisible(lapply(names(pvq),function(.name) set(pvq, which(is.infinite(pvq[[.name]])), j = .name,value =NA)))

# In summary, the following was done: Black box ML model was fit on DMSP levels
# in 2012. We leave 2013 data as a "test" set, which the model has not seen
# before, for which we can get the RMSE for our predicted measure of DMSP
# levels. Our ML model then predicts DMSP levels in 2012 and 2013 to get an
# estimate for the RMSE for this model. 

# Take log(predicted DMSP 2013) - log(predicted DMSP 2012) ~ log(actual DMSP
# 2013) - log(actual DMSP 2012). This gives us a fit with an intercept term t
# statistic ~ 20. This implies that the DMSP distribution is nonstationary. 
summary(lm(ln_gr_dm_actual ~ ln_gr_dm_pred, data = pvq))

# One can also fit a model of log(actual DMSP 2013) - log(actual DMSP 2012)  ~
# log(actual BM 2013) - log(actual BM 2012), in which case we again get a highly
# significant intercept term (t stat is now ~ 19). 
summary(lm(ln_gr_dm_actual ~ ln_gr_bm_actual, data = pvq))

# Thus, we do not attempt splicing

