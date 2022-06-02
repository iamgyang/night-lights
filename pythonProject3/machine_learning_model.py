# This fits a bunch of models on the training data using an auto-ML package developed by some Amazon AI people.
# https://arxiv.org/pdf/2003.06505.pdf
# Installation instructions here:
# https://auto.gluon.ai/stable/install.html
import os
from autogluon.tabular import TabularDataset, TabularPredictor

train_data = TabularDataset('https://autogluon.s3.amazonaws.com/datasets/Inc/train.csv')
subsample_size = 500  # subsample subset of data for faster demo, try setting this to much larger values
train_data = train_data.sample(n=subsample_size, random_state=0)
train_data.head()
label = 'class'
print("Summary of class variable: \n", train_data[label].describe())
save_path = 'C:/Users/user/Dropbox/CGD GlobalSat/HF_measures/input'  # specifies folder to store trained models

# Longest time you are willing to wait (in seconds)
time_limit = 60

# fit model
predictor = TabularPredictor(label=label, path=save_path).fit(train_data, time_limit = time_limit, presets='medium_quality')

# test set
test_data = TabularDataset('https://autogluon.s3.amazonaws.com/datasets/Inc/test.csv')

# values to predict
y_test = test_data[label]

# delete label column to prove we're not cheating
test_data_nolab = test_data.drop(columns=[label])
test_data_nolab.head()

# unnecessary, just demonstrates how to load previously-trained predictor from file
predictor = TabularPredictor.load(save_path)
y_pred = predictor.predict(test_data_nolab)
print("Predictions:  \n", y_pred)
perf = predictor.evaluate_predictions(y_true=y_test, y_pred=y_pred, auxiliary_metrics=True)
predictor.leaderboard(test_data, silent=True)

# predictor = TabularPredictor(label=<variable-name>).fit(train_data=<file-name>)
# pred_probs = predictor.predict_proba(test_data_nolab)
# pred_probs.head(5)
# results = predictor.fit_summary(show_plot=True)
# print("AutoGluon infers problem type is: ", predictor.problem_type)
# print("AutoGluon identified the following types of features:")
# print(predictor.feature_metadata)
# predictor.leaderboard(test_data, silent=True)
# predictor.predict(test_data, model='LightGBM')


# # specify your evaluation metric here
# metric = 'roc_auc'
# predictor = TabularPredictor(label, eval_metric=metric).fit(train_data, time_limit=time_limit, presets='best_quality')
# predictor.leaderboard(test_data, silent=True)
# age_column = 'age'
# print("Summary of age variable: \n", train_data[age_column].describe())
# predictor_age = TabularPredictor(label=age_column, path="agModels-predictAge").fit(train_data, time_limit=60)
# performance = predictor_age.evaluate(test_data)
# predictor_age.leaderboard(test_data, silent=True)