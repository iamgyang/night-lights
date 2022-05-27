# This R environment comes with all of CRAN preinstalled, as well as many other helpful packages
# The environment is defined by the kaggle/rstats docker image: https://github.com/kaggle/docker-rstats
# For example, here's several helpful packages to load in 

#library(ggplot2) # Data visualization
#library(readr) # CSV file I/O, e.g. the read_csv function

# Input data files are available in the "../input/" directory.
# For example, running this (by clicking run or pressing Shift+Enter) will list the files in the input directory

system("ls ../input")

# Any results you write to the current directory are saved as output.
# Loading libraries
library(tidyverse)
library(caret)
library(rpart)
library(xgboost)

# loading data
train <- read_csv("../input/train.csv")
test<-read_csv("../input/test.csv")

# only with numerical data
numvar <- names(train)[which(sapply(train, is.numeric))]
train <- train[,numvar]
numvar_test<-numvar[-length(numvar)]
test <- test[,numvar_test]

# Imputing NA's with median 
train %>% 
  mutate_all(~ifelse(is.na(.), median(., na.rm = TRUE), .)) -> train

test %>% 
  mutate_all(~ifelse(is.na(.), median(., na.rm = TRUE), .)) -> test

## Feature engineering, these columns increases the score
train %>% mutate(year_old = YrSold - YearBuilt, 
                 year_old_reno = YrSold - YearRemodAdd,
                 year_gar = YrSold - GarageYrBlt) -> train

test %>% mutate(year_old = YrSold - YearBuilt, 
                year_old_reno = YrSold - YearRemodAdd,
                year_gar = YrSold - GarageYrBlt) -> test

#Training with xgboost - gives better scores than 'rf'
trctrl <- trainControl(method = "cv", number = 5)

# Tested the above setting in local machine
tune_grid <- expand.grid(nrounds = 200,
                         max_depth = 5,
                         eta = 0.05,
                         gamma = 0.01,
                         colsample_bytree = 0.75,
                         min_child_weight = 0,
                         subsample = 0.5)

rf_fit <- train(SalePrice ~., data = train, method = "xgbTree",
                trControl=trctrl,
                tuneGrid = tune_grid,
                tuneLength = 10)

# have a look at the model 
rf_fit

# Testing
test_predict <- predict(rf_fit, test)

# Preparing to submit
kaggle.submit <- cbind(test$Id,test_predict)
write.table(kaggle.submit,file="submission1.csv",sep=",",
            quote=FALSE,col.names=c("Id","SalePrice"),row.names=FALSE)


# This is a minimal framework for training xgboost in R using caret to do the cross-validation/grid tuning
# and using the normalized gini metric for scoring. The # of CV folds and size of the tuning grid
# are limited to remain under kaggle kernel limits. To improve the score up the nrounds and expand
# the tuning grid.

library(data.table)
library(caret)
library(xgboost)
library(verification)

# Read train and test data
dtrain <- fread('../input/train.csv')
dtest <- fread('../input/test.csv')

# Check data size in memory
print("Training data size in RAM:");
print(object.size(dtrain), units = 'Mb')

# print training data dimensions
print(dim(dtrain))

# collect names of all categorical variables
cat_vars <- names(dtrain)[grepl('_cat$', names(dtrain))]

# turn categorical features into factors
dtrain[, (cat_vars) := lapply(.SD, factor), .SDcols = cat_vars]
dtest[, (cat_vars) := lapply(.SD, factor), .SDcols = cat_vars]

# one hot encode the factor levels
dtrain <- as.data.frame(model.matrix(~. - 1, data = dtrain))
dtest <- as.data.frame(model.matrix(~ . - 1, data = dtest))

# create index for train/test split
train_index <- sample(c(TRUE, FALSE), size = nrow(dtrain), replace = TRUE, prob = c(0.8, 0.2))

# perform x/y ,train/test split.
x_train <- dtrain[train_index, 3:ncol(dtrain)]
y_train <- as.factor(dtrain$target[train_index])

x_test <- dtrain[!train_index, 3:ncol(dtrain)]
y_test <- as.factor(dtrain$target[!train_index])

# Convert target factor levels to 0 = "No" and 1 = "Yes" to avoid this error when predicting class probs:
# https://stackoverflow.com/questions/18402016/error-when-i-try-to-predict-class-probabilities-in-r-caret
levels(y_train) <- c("No", "Yes")
levels(y_test) <- c("No", "Yes")

# normalized gini function taked from:
# https://www.kaggle.com/c/ClaimPredictionChallenge/discussion/703
normalizedGini <- function(aa, pp) {
  Gini <- function(a, p) {
    if (length(a) !=  length(p)) stop("Actual and Predicted need to be equal lengths!")
    temp.df <- data.frame(actual = a, pred = p, range=c(1:length(a)))
    temp.df <- temp.df[order(-temp.df$pred, temp.df$range),]
    population.delta <- 1 / length(a)
    total.losses <- sum(a)
    null.losses <- rep(population.delta, length(a)) # Hopefully is similar to accumulatedPopulationPercentageSum
    accum.losses <- temp.df$actual / total.losses # Hopefully is similar to accumulatedLossPercentageSum
    gini.sum <- cumsum(accum.losses - null.losses) # Not sure if this is having the same effect or not
    sum(gini.sum) / length(a)
  }
  Gini(aa,pp) / Gini(aa,aa)
}

# create the normalized gini summary function to pass into caret
giniSummary <- function (data, lev = "Yes", model = NULL) {
  levels(data$obs) <- c('0', '1')
  out <- normalizedGini(as.numeric(levels(data$obs))[data$obs], data[, lev[2]])  
  names(out) <- "NormalizedGini"
  out
}

# create the training control object. Two-fold CV to keep the execution time under the kaggle
# limit. You can up this as your compute resources allow. 
trControl = trainControl(
  method = 'cv',
  number = 2,
  summaryFunction = giniSummary,
  classProbs = TRUE,
  verboseIter = TRUE,
  allowParallel = TRUE)

# create the tuning grid. Again keeping this small to avoid exceeding kernel memory limits.
# You can expand as your compute resources allow. 
tuneGridXGB <- expand.grid(
  nrounds=c(350),
  max_depth = c(4, 6),
  eta = c(0.05, 0.1),
  gamma = c(0.01),
  colsample_bytree = c(0.75),
  subsample = c(0.50),
  min_child_weight = c(0))

start <- Sys.time()

# train the xgboost learner
xgbmod <- train(
  x = x_train,
  y = y_train,
  method = 'xgbTree',
  metric = 'NormalizedGini',
  trControl = trControl,
  tuneGrid = tuneGridXGB)

print(Sys.time() - start)

# make predictions
preds <- predict(xgbmod, newdata = x_test, type = "prob")
preds_final <- predict(xgbmod, newdata = dtest, type = "prob")

# convert test target values back to numeric for gini and roc.plot functions
levels(y_test) <- c("0", "1")
y_test_raw <- as.numeric(levels(y_test))[y_test]

# Diagnostics
print(xgbmod$results)
print(xgbmod$resample)

# plot results (useful for larger tuning grids)
plot(xgbmod)

# score the predictions against test data
normalizedGini(y_test_raw, preds$Yes)

# plot the ROC curve
roc.plot(y_test_raw, preds$Yes, plot.thres = c(0.02, 0.03, 0.04, 0.05))

# prep the predictions for submissions
sub <- data.frame(id = as.integer(dtest$id), target = preds_final$Yes)

# write to csv
write.csv(sub, 'xgb_submission.csv', row.names = FALSE)
