
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
save_pvq <- as.data.table(pvq)
pvq <- pvq[!is.na(dmsp_pos)]

# check that only years 2012-2013 exist in data:
waitifnot(length(setdiff(unique(pvq$year), c(2012, 2013)))==0)

setcolorder(pvq, c("OBJECTID", "year", "dmsp_pos", "ln_sum_pix_dmsp"))

# for all values that are infinite, turn it into NA values
invisible(lapply(names(pvq),function(.name) set(pvq, which(is.infinite(pvq[[.name]])), j = .name,value =NA)))

# # convert DMSP positive to factor
pvq[,dmsp_pos:=factor((dmsp_pos), levels = c(1, 0))]

# split train (2012) and test (2013):
dtrain <- pvq[year == 2012]
dtest <- pvq[year == 2013]

# export for Python ML model
setwd(input_dir)
dtrain %>% write.csv("train.csv", na = "", row.names = FALSE)
dtest %>% write.csv("test.csv", na = "", row.names = FALSE)
save_pvq %>% write.csv("full_data_splicing.csv", na = "", row.names = FALSE)
save.image("merging_midpoint.RData")
load("merging_midpoint.RData")

# Run ML model in Python -----------------------------------------------------

# load back in the predicted results from python
dtest <- fread("test_data_splicing_with_predictions.csv")

# Graphs and Diagnostics --------------------------------------------------

setnames(dtest, "ln_sum_pix_dmsp_pred", "pred")
dtest[, resid := ln_sum_pix_dmsp - pred]

# actual vs. predicted
PLOT <- ggplot(dtest, aes(y = pred, x = ln_sum_pix_dmsp)) + 
  geom_point(shape = 21) + 
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

