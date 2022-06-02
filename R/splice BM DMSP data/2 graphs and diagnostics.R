
# load back in the predicted results from python
dtest <- fread("test_data_splicing_with_predictions.csv")

# Graphs and Diagnostics --------------------------------------------------

setnames(dtest, "sum_pix_dmsp_pred", "pred")
dtest[, resid := sum_pix_dmsp - pred]

# actual vs. predicted
PLOT <- ggplot(dtest, aes(y = pred, x = sum_pix_dmsp)) + 
  geom_point(shape = 21) + 
  my_custom_theme + 
  labs(
    y = "Predicted DMSP pixels", 
    x = "Actual DMSP pixels", 
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
    x = "Predicted DMSP pixels", 
    y = "Residual", 
    title = "Residual vs. fitted plot for test sample (2013)",
    subtitle = c("Tree-based model trained on data in 2012.")
  ) + 
  geom_abline(slope = 0, intercept = 0)

ggsave("residual_v_predict_test.pdf", PLOT, width = 14, height = 14)

