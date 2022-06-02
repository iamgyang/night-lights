# example 2 ---------------------------------------------------------------

load("merging_midpoint.RData")

xgb_wrapper <- function(train_data,
                        target_variable,
                        excluded_vars,
                        categorical = FALSE,
                        cv_num = 10,
                        tune_grid_row_size = 100,
                        seed_train = 94720204,
                        name_model = "Model") {
    
    # convert to data.table if not already
    train_data <- as.data.table(train_data)
    
    # Check data size in memory
    print("Training data size in RAM:")
    print(object.size(train_data), units = 'Mb')
    
    # print training data dimensions
    print(dim(train_data))
    
    # remove variables that are not interesting
    train_data[, c(excluded_vars) := NULL]
    
    set.seed(seed_train)
    train_data <- train_data[!is.na(eval(as.name(target_variable)))]
    
    # create learning task
    task <- TaskRegr$new(id = name_model,
                         backend = train_data,
                         target = target_variable)
    
    # Tune hyperparameters ----------------------------------------------------
    
    # create cross validation object
    crossval = rsmp("cv", folds = cv_num)
    
    # reproducible results
    set.seed(seed_train)
    
    # populate the folds. NB: mlr3 will only use data where role was set to "use"
    crossval$instantiate(task)
    
    # to see all measures use mlr_measures$help()
    measure <- NULL
    if (categorical) {
        measure <- msr("classif.ce")
    } else {
        measure <- msr("regr.mae")
        # measure <- msr("regr.rmse")
    }
    
    # Searching hyper-parameter space needs to be customised to each model, so we
    # can't set up a common framework here. However, to control computations, it is
    # useful to set a limit on the number of searches that can be performed in a
    # tuning exercise. mlr3 offers a number of different options for terminating
    # searches - here we are just going to use the simplest one - where only a
    # limited number of evaluations are permitted.
    
    # using a low number so things run quickly
    evals_trm = trm("evals", n_evals = tune_grid_row_size)
    
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
    
    if (categorical) {
        learner_xgb <- lrn("classif.xgboost")
    } else {
        learner_xgb <- lrn("regr.xgboost")
    }
    
    instance_xgboost <- TuningInstanceSingleCrit$new(
        task = task,
        learner = learner_xgb,
        resampling = crossval,
        measure = measure,
        search_space = tune_ps_xgboost,
        terminator = evals_trm
    )
    
    # need to make a new tuner with resolution 4
    # tuner <- tnr("grid_search", resolution = 4)
    set.seed(seed_train)  # for random search for reproducibility
    tuner <- tnr("random_search")
    
    lgr::get_logger("bbotk")$set_threshold("warn")
    lgr::get_logger("mlr3")$set_threshold("warn")
    
    time_bef <- Sys.time()
    
    # this is where it actually gets done
    tuner$optimize(instance_xgboost)
    
    lgr::get_logger("bbotk")$set_threshold("info")
    lgr::get_logger("mlr3")$set_threshold("info")
    
    # Time difference
    print(Sys.time() - time_bef)
    
    # Train on full training set -----------------------------------------------------
    
    # The hyper-parameter tuning results are subject to randomness, first due to the
    # specification of the cross-validation folds and second due to the random
    # search). We'll use these when looking at the model.
    
    lrn_xgboost_tuned = lrn("regr.xgboost")
    lrn_xgboost_tuned$param_set$values = instance_xgboost$result_learner_param_vals
    lrn_xgboost_tuned$train(task)
    
    return(list("model" = lrn_xgboost_tuned,
                "results" = instance_xgboost$result))
    
}