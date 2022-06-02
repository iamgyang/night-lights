# example 2 ---------------------------------------------------------------

xgb_wrapper <- function(train_data,
                        target_variable,
                        excluded_vars,
                        categorical = FALSE, 
                        method_ = 'xgbTree',
                        cv_num = 10,
                        tune_grid_row_size = 100,
                        seed_train = 94720204) {

load("merging_midpoint.RData")

# remove variables that are not interesting
dtrain[, c("dmsp_pos",
           "OBJECTID",
           "year",
           "row_num") := NULL]

set.seed(983409)
dtrain <- dtrain[!is.na(ln_sum_pix_dmsp)]
dtrain_samp <- sample_n(dtrain, 100) # !!!!!!!!!!!!!CHANGE

# create learning task
task <- TaskRegr$new(id = "lights",
                     backend = dtrain_samp,
                     target = "ln_sum_pix_dmsp")

# create object
crossval = rsmp("cv", folds = 2) # !!!!!!!!!!!!!CHANGE

# reproducible results
set.seed(42)

# populate the folds
# NB: mlr3 will only use data where role was set to “use”
crossval$instantiate(task)

# to see all measures use
# mlr_measures$help()
# follow the links for a specific one, or you can type
# ?mlr_measures_regr.rmse to get help for RMSE, and then insert the
# other names for others, eg ?mlr_measures_regr.rmsle etc
# measure <- msr("regr.rmse")
measure <- msr("regr.mae")

# Searching hyper-parameter space needs to be customised to each model, so we
#can’t set up a common framework here. However, to control computations, it is
#useful to set a limit on the number of searches that can be performed in a
#tuning exercise. mlr3 offers a number of different options for terminating
#searches - here we are just going to use the simplest one - where only a
#limited number of evaluations are permitted.# setting we used to get the
#xgboost results below evals_trm = trm("evals", n_evals = 500)

# using a low number so things run quickly
evals_trm = trm("evals", n_evals = 25) # !!!!!!!!!!!!!CHANGE

tune_ps_xgboost <- ps(
    # eta can be up to 1, but usually it is better to use low eta, and tune
    # nrounds for a more fine-grained model
    eta = p_dbl(lower = 0.005, upper = 0.3),
    
    # select value for gamma tuning can help overfitting
    gamma = p_dbl(0.01, 0.5),
    
    # We know that the problem is not that deep in interactivity so we search a
    # low depth
    max_depth = p_int(lower = 2, upper = 6),
    
    # nrounds to stop overfitting
    nrounds = p_int(lower = 100, upper = 2000),
    
    colsample_bytree = p_dbl(0, 1),
    
    subsample = p_dbl(0, 1),
    
    min_child_weight = p_int(0, 20)
)

instance_xgboost <- TuningInstanceSingleCrit$new(
    task = task,
    learner = lrn("regr.xgboost"),
    resampling = crossval,
    measure = measure,
    search_space = tune_ps_xgboost,
    terminator = evals_trm
)

# need to make a new tuner with resolution 4
# tuner <- tnr("grid_search", resolution = 4)
set.seed(84)  # for random search for reproducibility
tuner <- tnr("random_search")

lgr::get_logger("bbotk")$set_threshold("warn")
lgr::get_logger("mlr3")$set_threshold("warn")

time_bef <- Sys.time()

# this is where it actually gets done
tuner$optimize(instance_xgboost)

lgr::get_logger("bbotk")$set_threshold("info")
lgr::get_logger("mlr3")$set_threshold("info")

Sys.time() - time_bef
## Time difference of 1.711818 mins

instance_xgboost$result_learner_param_vals
instance_xgboost$result

# However, remember that these results are from 25 evaluations only, and with 4
# hyper-parameters, we’d really like to use more evaluations. The model above
# isn't a particularly good one

# The table below shows the results we got from 500 evaluations along with the
# results we got in earlier development work for this article (the
# hyper-parameter tuning results are subject to randomness, first due to the
# specification of the cross-validation folds and second due to the random
# search). We’ll use these when looking at the model.

# If, instead, you would like to fit the XGBoost model found after 25
# evaluations, you can use the code below to pick up the selected values after
# tuning. This replaces the model fitted above using the hyper-parameters found
# after 500 evaluations.

lrn_xgboost_tuned = lrn("regr.xgboost")
lrn_xgboost_tuned$param_set$values = instance_xgboost$result_learner_param_vals
lrn_xgboost_tuned$train(task)

return(lrn_xgboost_tuned)

}