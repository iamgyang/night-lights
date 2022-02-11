library(data.table)
library(fixest)
library(modelsummary)

DT <- CJ(ID = c("Bob", "Alice"),
         year = 1992:2020)

# make observations
DT[, truth := runif(nrow(DT))]

# create fixed effects
DT[, ID_FE := ifelse(ID == "Bob", 0.5, 1)]
DT[, year_FE := ifelse(year >= 2000, 0.3, 1)]

# create observed variable:
DT[, observed := (truth + year_FE) * ID_FE]

# create additive means
DT[, ID_mean := mean(observed), by = .(ID)]
DT[, year_mean := mean(observed), by = .(year)]

# create multiplicative means
DT[, ID_log_mean := mean(log(observed)), by = .(ID)]
DT[, year_log_mean := mean(log(observed)), by = .(year)]
DT[, ln_observed := log(observed)]

# create differences for manual FE estimation
DT[, diff_ln_observed := ln_observed - ID_log_mean - year_log_mean]
DT[, diff_observed := observed - ID_mean - year_mean]
DT[, av_diff_observed:= exp(diff_ln_observed)*diff_observed]

# get actual Y
DT[, Y := truth ^ 0.3]
DT[, ln_Y := log(Y)]

# run regression
true_relationship <- lm(ln_Y~log(truth),data = DT)
m1 <- lm(ln_Y ~ diff_ln_observed, data = DT)
twfe <-feols(ln_Y ~ log(observed) |as.factor(ID) + as.factor(year),data = DT)
msummary(list(true_relationship, m1, twfe))

library(readstata13)
readstata13::save.dta13(DT, "test_FE.dta")