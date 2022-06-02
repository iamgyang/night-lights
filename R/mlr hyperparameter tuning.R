{mlr3} framework

With {mlr3}, I personally think the preprocessing step doesn’t have a lot of functionality as the {tidymodels} framework but the nested resampling procedure looks more straightforward and clean. Let’s load the packages and go through some of the steps in {mlr3} now.

p_load(mlr3, mlr3learners)

# create learning task
task_credit <- TaskClassif$new(id = "credit", backend = credit_data, target = "Status")
task_credit

## <TaskClassif:credit> (4454 x 14)
## * Target: Status
## * Properties: twoclass
## * Features (13):
##   - int (9): Age, Amount, Assets, Debt, Expenses, Income, Price,
##     Seniority, Time
##   - fct (4): Home, Job, Marital, Records

We don’t necessarily need to split the data like we did for {tidymodels}. Let’s also load the random forest learner that we’ll use for the cross validation for tuning the hyperparameters. We need to also specify the resampling strategy (4 fold cross validation) and the metric we’ll use (AUROC) for assessing the performance of the models.

# load learner 
learner <- lrn("classif.ranger", predict_type = "prob")

# specify the resampling strategy... we'll use 4-fold cross-validation 
cv_4 = rsmp("cv",folds=4)
measure = msr("classif.auc")

Now we need to setup the tuning process. Let’s first setup the tuning termination object. We set trm('evals',n_evals=20) such that for every resampling fold we’ll stop at 20 random grid searched sets of parameters.

# We also need to specify if we're going to trim the tuning process.. we won't
p_load(mlr3tuning)
eval20 <- trm('evals',n_evals=5)
# for no termination restriction
# evalnon <- trm('none')

We also want to setup the preprocessing similar to how we did it using the {tidymodels} framework. This involves a pipline approach by setting up pipline operations po(). One difference between the ’{tidymodels}framework on the{mlr3}framework is that thestep_unknown(),step_other()andstep_novel()does not seem to exist for the{mlr3}` framework.

# We're also going to utilize the {mlr3pipelines} package framework. We need to basically string together the preprcoessing, hyper parameter tuning, and final 
p_load(mlr3pipelines)

# I have not found a easy way to convert NA values to  'unknown' so we'll just go ahead and impute the class labels for the factor variables
sampleimpute <- po('imputesample')

# The below code should work but doesn't for some reason
# mutate$param_set$values$mutation <- list(
#   # across(where(is.factor), ~ifelse(is.na(.),"unknown",.))
#   Home = ~ ifelse(is.na(Home), "unknown",Home),
#   Job = ~ ifelse(is.na(Job), "unknown",Job),
#   Marital = ~ ifelse(is.na(Marital), "unknown",Marital)
# )

# median imputation for missing numeric
medimpute <- po("imputemedian")

# The combining of infrequent categories not an easy task in mlr3 framework
# ALso step_novel like function does not exist in mlr3

# Lastly one-hot encoding
ohencode <- po("encode")

graph <- sampleimpute %>>%
  # graph <- mutate %>>%
  medimpute %>>%
  ohencode %>>%
  learner

Another framework the {mlr3} ecosystem utilize is a GraphLearner which takes graphs and strings together the preprocessing, hyperparameter tuning, and prediction process as a Graph Network. I won’t go into the details but if you’re interested you should check out this page.

# Generate graph learner to combine preprocessing, tuning, and predicting
glrn = GraphLearner$new(graph)

# Tuning the same 3 parameters mtry  trees min_n

# Previously with tidymodels we used the below:
# mtry() %>% range_set(c(1, 20)),
# trees() %>% range_set(c(500, 1000)), 
# min_n() %>% range_set(c(2, 10)),

# Notice the name of the parameters is different from what was used in the `{tidymodels}` framework.
p_load(paradox)
search_space = ps(
  classif.ranger.mtry = p_int(lower = 1, upper = 10),
  classif.ranger.num.trees = p_int(lower = 500, upper = 1000),
  classif.ranger.min.node.size = p_int(lower = 2, upper = 10)
)

We can also take a look at the whole machine learning pipeline through the graph plot.

# Check graph of the whole process
graph$plot(html=FALSE)

Now let’s generate a AutoTuner class object such that we can run the inner resampling for hyperparater tuning with it. We’re going to do a random grid search on the hyperparameter space based on the search_space constructed and terminate after 20 evaulations. I also have code commented out below that one can use if they want to do a grid search with

.

# Nested resampling for parameter tuning as well as prediction
# This whole nested resampling could be expensive so use multiprocess
at = AutoTuner$new(
  glrn, 
  cv_4, 
  measure, 
  eval20, 
  tnr("random_search"), 
  search_space,
  store_tuning_instance = TRUE
)

# for random grid search with 20 combination searched use below
# tuner = tnr("random_search")
# for grid search with specific resolution (i.e. 5 means 5^n parameters)
# tuner = tnr("grid_search", resolution=5)

For the outer resampling (i.e., test set evaluation), we’ll do a holdout resampling to test the best hyperparameter set from the training data on 20% of the test set data.

# We will use a holdout resample for the outer split so that we have 20% as a test set
resampling_outer <- rsmp('holdout', ratio = 0.8)
# resampling_outer <- rsmp('cv', folds = 3)

Since we want to run this whole thing in a parallel fashion, we’ll use the {future} package.

future::plan('multisession')

Now we’re ready to run the nested resampling task. We’re going to store the models in order to evaluate the performance of the inner resampling (use store_models=TRUE)

rr <- resample(
  task = task_credit, learner = at, resampling = resampling_outer, store_models = TRUE
)

## INFO  [11:07:18.254] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger.tuned' on task 'credit' (iter 1/1) 
## INFO  [11:07:18.592] [bbotk] Starting to optimize 3 parameter(s) with '<OptimizerRandomSearch>' and '<TerminatorEvals> [n_evals=5]' 
## INFO  [11:07:18.650] [bbotk] Evaluating 1 configuration(s) 
## INFO  [11:07:18.703] [mlr3]  Running benchmark with 4 resampling iterations 
## INFO  [11:07:18.725] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 3/4) 
## INFO  [11:07:21.275] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 2/4) 
## INFO  [11:07:22.895] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 4/4) 
## INFO  [11:07:24.569] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 1/4) 
## INFO  [11:07:26.293] [mlr3]  Finished benchmark 
## INFO  [11:07:26.365] [bbotk] Result of batch 1: 
## INFO  [11:07:26.369] [bbotk]  classif.ranger.mtry classif.ranger.num.trees classif.ranger.min.node.size 
## INFO  [11:07:26.369] [bbotk]                    3                      713                            9 
## INFO  [11:07:26.369] [bbotk]  classif.auc                                uhash 
## INFO  [11:07:26.369] [bbotk]    0.8327978 1fd24ee7-55a6-49a4-ac21-301d37d054e9 
## INFO  [11:07:26.375] [bbotk] Evaluating 1 configuration(s) 
## INFO  [11:07:26.425] [mlr3]  Running benchmark with 4 resampling iterations 
## INFO  [11:07:26.434] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 1/4) 
## INFO  [11:07:29.606] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 3/4) 
## INFO  [11:07:33.068] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 4/4) 
## INFO  [11:07:36.436] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 2/4) 
## INFO  [11:07:39.727] [mlr3]  Finished benchmark 
## INFO  [11:07:39.831] [bbotk] Result of batch 2: 
## INFO  [11:07:39.833] [bbotk]  classif.ranger.mtry classif.ranger.num.trees classif.ranger.min.node.size 
## INFO  [11:07:39.833] [bbotk]                    6                      981                            2 
## INFO  [11:07:39.833] [bbotk]  classif.auc                                uhash 
## INFO  [11:07:39.833] [bbotk]    0.8291453 0ed1c7fe-605f-4e81-89b9-7cb55366f9a4 
## INFO  [11:07:39.838] [bbotk] Evaluating 1 configuration(s) 
## INFO  [11:07:39.878] [mlr3]  Running benchmark with 4 resampling iterations 
## INFO  [11:07:39.885] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 4/4) 
## INFO  [11:07:40.806] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 3/4) 
## INFO  [11:07:41.687] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 1/4) 
## INFO  [11:07:42.568] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 2/4) 
## INFO  [11:07:43.506] [mlr3]  Finished benchmark 
## INFO  [11:07:43.573] [bbotk] Result of batch 3: 
## INFO  [11:07:43.575] [bbotk]  classif.ranger.mtry classif.ranger.num.trees classif.ranger.min.node.size 
## INFO  [11:07:43.575] [bbotk]                    1                      882                            5 
## INFO  [11:07:43.575] [bbotk]  classif.auc                                uhash 
## INFO  [11:07:43.575] [bbotk]    0.8237262 537e29c1-b965-49c3-9c20-b3a41a9dd07e 
## INFO  [11:07:43.580] [bbotk] Evaluating 1 configuration(s) 
## INFO  [11:07:43.621] [mlr3]  Running benchmark with 4 resampling iterations 
## INFO  [11:07:43.628] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 1/4) 
## INFO  [11:07:45.782] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 3/4) 
## INFO  [11:07:47.686] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 4/4) 
## INFO  [11:07:49.640] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 2/4) 
## INFO  [11:07:51.664] [mlr3]  Finished benchmark 
## INFO  [11:07:51.740] [bbotk] Result of batch 4: 
## INFO  [11:07:51.742] [bbotk]  classif.ranger.mtry classif.ranger.num.trees classif.ranger.min.node.size 
## INFO  [11:07:51.742] [bbotk]                    6                      622                            7 
## INFO  [11:07:51.742] [bbotk]  classif.auc                                uhash 
## INFO  [11:07:51.742] [bbotk]    0.8291652 c0be6817-49fb-4cbd-928a-5dabc538ff8c 
## INFO  [11:07:51.746] [bbotk] Evaluating 1 configuration(s) 
## INFO  [11:07:51.785] [mlr3]  Running benchmark with 4 resampling iterations 
## INFO  [11:07:51.792] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 1/4) 
## INFO  [11:07:53.668] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 4/4) 
## INFO  [11:07:55.543] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 2/4) 
## INFO  [11:07:57.432] [mlr3]  Applying learner 'imputesample.imputemedian.encode.classif.ranger' on task 'credit' (iter 3/4) 
## INFO  [11:07:59.394] [mlr3]  Finished benchmark 
## INFO  [11:07:59.468] [bbotk] Result of batch 5: 
## INFO  [11:07:59.470] [bbotk]  classif.ranger.mtry classif.ranger.num.trees classif.ranger.min.node.size 
## INFO  [11:07:59.470] [bbotk]                    8                      584                           10 
## INFO  [11:07:59.470] [bbotk]  classif.auc                                uhash 
## INFO  [11:07:59.470] [bbotk]    0.8298606 eb98c038-eebd-4d4a-8c54-0f4c8086fb77 
## INFO  [11:07:59.481] [bbotk] Finished optimizing after 5 evaluation(s) 
## INFO  [11:07:59.482] [bbotk] Result: 
## INFO  [11:07:59.484] [bbotk]  classif.ranger.mtry classif.ranger.num.trees classif.ranger.min.node.size 
## INFO  [11:07:59.484] [bbotk]                    3                      713                            9 
## INFO  [11:07:59.484] [bbotk]  learner_param_vals  x_domain classif.auc 
## INFO  [11:07:59.484] [bbotk]           <list[5]> <list[3]>   0.8327978

Let’s check the tuning results.

# The final hyper parameter selected and the training set AUC results
rr$learners[[1]]$tuning_result

##    classif.ranger.mtry classif.ranger.num.trees classif.ranger.min.node.size
## 1:                   3                      713                            9
##    learner_param_vals  x_domain classif.auc
## 1:          <list[5]> <list[3]>   0.8327978

# Aggregate performance from the 3 outer resampling datasets after the 5 inner resampling for hyperparameter tuning

The test set results are presented below.

# Using the hyper parameter selected from the training set if we predict using the test set we get the below
rr$score(msr("classif.auc"))

##                 task task_id         learner
## 1: <TaskClassif[46]>  credit <AutoTuner[38]>
##                                               learner_id
## 1: imputesample.imputemedian.encode.classif.ranger.tuned
##                 resampling resampling_id iteration              prediction
## 1: <ResamplingHoldout[19]>       holdout         1 <PredictionClassif[19]>
##    classif.auc
## 1:   0.8146165

rr$aggregate(msr("classif.auc"))

## classif.auc 
##   0.8146165

rr$prediction()$confusion

##         truth
## response bad good
##     bad   95   53
##     good 153  590

Let’s visualize the test set predictions now.

# Plots
p_load(mlr3viz,precrec)

autoplot(rr, measure = msr('classif.auc'))

autoplot(rr, type = "histogram")

## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.

autoplot(rr, type = "roc")

autoplot(rr, type = "prc")

There you have it!
  Conclusion

Overall, I like both frameworks but it looks like both have a few areas that could improve. Overall, both development team has done a great job and I’ll likely use both frameworks so that I can benefit from what both packages offer. I hope the above codes were helpful and I’ll likely be posting a few more analyses using both packages so stay tuned!
  