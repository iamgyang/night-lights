# This fits 2 models on the training data using an auto-ML package developed by
# some Amazon AI people.
# https://arxiv.org/pdf/2003.06505.pdf
# Installation instructions here:
# https://auto.gluon.ai/stable/install.html

# import packages
import os
from autogluon.tabular import TabularDataset, TabularPredictor

# set working directory. this folder will also store the trained ML models
dir_path = 'C:/Users/user/Dropbox/CGD GlobalSat/HF_measures/input'
save_path = 'C:/Users/user/Dropbox/CGD GlobalSat/splice_final_model'
os.chdir(dir_path)

# STEP 1: FIT 2 MODELS ------------------------------------------------------------
categorical = False

# import data
train_data = TabularDataset('train.csv')
test_data = TabularDataset('test.csv')
full_data = TabularDataset('full_data_splicing.csv')

if (categorical):
    label = 'dmsp_pos'
    exclude_label = 'ln_sum_pix_dmsp'

    # make sure the response variable is of the correct class
    train_data[label] = train_data[label].astype(str)
    test_data[label] = test_data[label].astype(str)

    # additional folder
    path_addendum = "categorical"

    # evaluation metric
    eval_metric = "mcc"
else:
    label = 'ln_sum_pix_dmsp'
    exclude_label = 'dmsp_pos'

    # make sure the response variable is of the correct class
    train_data[label] = train_data[label].astype(float)
    test_data[label] = test_data[label].astype(float)

    # additional folder
    path_addendum = "continuous"

    # evaluation metric
    eval_metric = "mae"

# remove data that are unnecessary
train_data = train_data.drop(columns=["OBJECTID", "year", "sum_pix_dmsp",  exclude_label])

# make sure train and test data column/variable names are all the same
# assert(all(train_data.columns == test_data.columns))

# model parameters. subsample subset of data for faster demo, try setting this
# to much larger values
# subsample_size = 500
# train_data = train_data.sample(n=subsample_size, random_state=0)
train_data.head()
print("Summary of class variable: \n", train_data[label].describe())

# Longest time you are willing to wait (in seconds)
time_limit = 3*60*60
# time_limit = 20

# fit model
predictor = TabularPredictor(label=label, path=f"{save_path}/{path_addendum}").fit(train_data, time_limit = time_limit, presets='best_quality', eval_metric = eval_metric)

# STEP 2: Predict on the test set: -----------------------------------------------------------

# load previously-trained categorical predictor from file:
predictor_conti = TabularPredictor.load(f"{save_path}/continuous")
results = predictor_conti.fit_summary(show_plot=True)

# make probability predictions:
test_data["ln_sum_pix_dmsp_pred_final"] = predictor_conti.predict(test_data)
test_data = test_data.dropna()

# evaluation:
perf = predictor_conti.evaluate_predictions(
    y_true = test_data[label],
    y_pred = test_data["ln_sum_pix_dmsp_pred_final"], 
    auxiliary_metrics = True)
predictor_conti.leaderboard(test_data, silent=True)
rmse_test = abs(perf['root_mean_squared_error']) # CHANGE! -- make it the actual RMSE

# predict upper and lower bounds for the new dataset of BM from 2014-2022:
full_data["ln_sum_pix_dmsp_pred"] = predictor_conti.predict(full_data)
full_data["ln_sum_pix_dmsp_pred_upper"] = full_data["ln_sum_pix_dmsp_pred"] + 1.96 * rmse_test
full_data["ln_sum_pix_dmsp_pred_lower"] = full_data["ln_sum_pix_dmsp_pred"] - 1.96 * rmse_test

# export
full_data.to_csv('full_data_splicing_with_predictions.csv')
test_data.to_csv('test_data_splicing_with_predictions.csv')
