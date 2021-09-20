# Packages ----------------------------------

list.of.packages <- c("base","car","cowplot","dplyr","ggplot2","ggthemes","graphics","grDevices","grid","gridExtra","gvlma","h2o","lubridate","MASS","readxl","rio","rms","rsample","stats","tidyr","utils","zoo", "xtable", "stargazer", "data.table", "ggrepel", "foreign", "fst", "data.table", "countrycode", "wbstats", "quantmod", "R.utils", "leaps", "bestglm", "dummies", "caret","lubridate", "jtools", "stargazer", "huxtable", "rio", "haven", "ResourceSelection", "gvlma", "betareg","quantreg", "margins", "plm", "collapse", "xtable", "R.utils", "kableExtra", "tinytex", "LambertW", "scales", "stringr", "imputeTS", "shadowtext", "pdftools", "glue", "purrr")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages)) install.packages(new.packages, dependencies = TRUE)
for (package in list.of.packages) {library(eval((package)), character.only = TRUE)}

# set GGPLOT default theme:
theme_set(theme_clean() + theme(plot.background = element_rect(color = "white")))


# Functions ----------------------------------

coalesce2 <- function(...) {
  Reduce(function(x, y) {
    i <- which(is.na(x))
    if(class(x)[1]!=class(y)[1]) stop("ahh! classes don't match")
    x[i] <- y[i]
    x
  },
  list(...))
} # function from mrip https://stackoverflow.com/questions/19253820/how-to-implement-coalesce-efficiently-in-r

dfcoalesce <- function(df_, newname, first, second) {
  df_ <- as.data.frame(df_)
  df_[,newname] <- coalesce2(df_[,first],
                             df_[,second])
  df_[,first] <- NULL
  df_[,second] <- NULL
  df_
}

# function that coalesces any duplicates (.x, .y):
# note: it only merges the names that have .x and .y at the END
# you must make sure that things are properly labeled as "NA" from the beginning
dfcoalesce.all <- function(df_){
  df_ <- as.data.frame(df_)
  tocolless.1 <- names(df_)[grep("\\.x", names(df_))]
  tocolless.2 <- names(df_)[grep("\\.y", names(df_))]
  tocolless.1 <- gsub("\\.x", "", tocolless.1)
  tocolless.2 <- gsub("\\.y", "", tocolless.2)
  tocolless <- intersect(tocolless.1, tocolless.2)
  
  for (n_ in tocolless) {
    first <- paste0(n_, ".x")
    second <- paste0(n_, ".y")
    different <- sum(na.omit(df_[,first]==df_[,second])==FALSE)
    # error if there is something different between the two merges:
    cat(paste0(" For the variable ",n_,", you have ", different, " differences between the x and y column. \n Coalesced while keeping x column as default. \n"))
    df_ <- dfcoalesce(
      df_,
      newname = n_,
      first = paste0(n_, ".x"),
      second = paste0(n_, ".y")
    )
  }
  df_
}

# create a function that STOPS my code if it runs into an error:
waitifnot <- function(cond) {
  if (!cond) {
    msg <- paste(deparse(substitute(cond)), "is not TRUE")
    if (interactive()) {
      message(msg)
      while (TRUE) {}
    } else {
      stop(msg)
    }
  }
}

# insert line breaks into paragraph for commenting
con <- function(string_) {cat(strwrap(string_, 60),sep="\n")}

# import all sheets into list from excel
read.xl.sheets <- function(Test_Cases,...) {
  names.init<-excel_sheets(Test_Cases)
  test.ex<-list()
  counter<-1
  for (val in names.init) {
    test.ex[[counter]]<-as.data.frame(read_excel(Test_Cases,sheet=val,...))
    counter<-counter+1
  }
  names(test.ex)<-names.init
  test.ex <- lapply(test.ex, as.data.table)
  test.ex
}

# clean names
name.df <- function(df){names(df) <- tolower(make.names(names(df))) %>% gsub("..",".",.,fixed=TRUE) %>% gsub("[.]$","",.); df}

# country code interactive
code2name <- function(x) {countrycode(x,"iso3c","country.name")}
name2code <- function(x) {countrycode(x,"country.name","iso3c")}

# automatically convert columns to numeric:
auto_num <- function(df_, sample_=10 , cutoff_ = 7){
  to_numeric <- sample_n(df_, sample_, replace = T) %>%
    lapply(function(x)
      sum(as.numeric(grepl("[0-9]", x))) >= cutoff_)
  to_numeric <- unlist(names(to_numeric)[to_numeric == TRUE])
  setDT(df_)[, (to_numeric) := lapply(.SD, as.numeric), .SDcols = to_numeric]
  df_
}

# create a function that counts number of NA elements within a row
fun4 <- function(indt) indt[, num_obs := Reduce("+", lapply(.SD, is.na))]  

# DHS ---------------------------------------------------------------------

# setwd("C:/Users/user/Downloads/StandardDHS_IR/StandardDHS_IR")
# imp <- list()
# for (i_ in dir(pattern = "dta|DTA")) {
#   imp[[i_]] <- rio::import(i_)
# }
# imp$AFIR70FL.DTA
# 

# var.labels <- attr(imp[[1]],"var.labels")

# Data------------------------------------------

lmss <- fread(
  "country	year
Albania	2012
Nigeria	2018-2020
Niger	2014-2015
Armenia	1996
Serbia and Montenegro	2002
Serbia and Montenegro	2003
Malawi	2004-2005
Jamaica	2000
Serbia	2007
Ghana	1991-1992
Iraq	2012-2013
Uganda	2011-2012
Uganda	2018-2019
Tanzania	2008-2009
Jamaica	1994
Jamaica	1996
Jamaica	1991
Jamaica	1992
Jamaica	1990
Jamaica	1989
Jamaica	1988
Jamaica	1989-1990
Jamaica	1993
Jamaica	1995
Jamaica	1997
Tanzania	1991-1994
Uganda	2010-2011
Burkina Faso	2014
Tanzania	1993-1994
Nepal	2003-2004
Uganda	2005-2010
Uganda	2015-2016
Ethiopia	2018-2019
Uganda	2013-2014
Vietnam	2006
Vietnam	2004
Bulgaria	2001
Tanzania	2016
Nepal	2010-2011
Tajikistan	1999
Vietnam	2002
Tanzania	2010
Tanzania	2013-2016
Albania	2008
Bulgaria	2007
Albania	2005
China	1995-1997
Kazakhstan	1996
Kyrgyz Republic	1996
Kyrgyz Republic	1997
Kyrgyz Republic	1998
Albania	2002
Tajikistan	2007
Ghana	2009-2010
Ethiopia	2015-2016
Bosnia-Herzegovina	2001
Bulgaria	1995
Bulgaria	1997
Niger	2011-2012
Nigeria	2015-2016
Tanzania	2008-2015
Côte d'Ivoire	1988-1989
Côte d'Ivoire	1985-1986
Côte d'Ivoire	1986-1987
Côte d'Ivoire	1987-1988
Kosovo	2000
Bosnia-Herzegovina	2004-2005
Tanzania	2012-2013
Ethiopia	2013-2014
Malawi	2019-2020
Malawi	2016-2017
Tanzania	2014-2015
Tanzania	2014-2015
Tanzania	2010-2011
Nepal	1995-1996
Malawi	2010-2011
Malawi	2010-2016
Mali	2020
Nicaragua	1993
Albania	1996
Bosnia-Herzegovina	2002-2003
Timor-Leste	2007-2008
Vietnam	1992-1993
Nigeria	2012-2013
Iraq	2006-2007
Timor-Leste	2001
Azerbaijan	1995
Malawi	2010-2019
Uganda	2020
Vietnam	1997-1998
Albania	2003
Malawi	2010-2013
Ghana	1998-1999
Albania	2004
Pakistan	1991
Tanzania	2004
Brazil	1996-1997
South Africa	1993
Malawi	2020-2021
Burkina Faso	2020-2021
"
)

ilostat <- fread("country	year
Afghanistan	2017
Afghanistan	2014
Afghanistan	2012
Afghanistan	2008
Albania	2012
Angola	2011
Angola	2009
Angola	2004
Armenia	2017
Armenia	2016
Armenia	2015
Barbados	2016
Bolivia	2019
Bolivia	2018
Bolivia	2017
Bolivia	2015
Bolivia	2014
Bolivia	2006
Bolivia	2005
Burundi	2014
Cambodia	2017
Cambodia	2016
Cambodia	2015
Cambodia	2014
Cambodia	2013
Cameroon	2007
Chad	2018
China	1988
Colombia	2015
Colombia	2014
Colombia	2013
Colombia	2012
Congo	2005
Cook Islands	2016
Egypt	2012-2013
Egypt	2010-2011
Egypt	2008-2009
Ghana	2017
Ghana	2013
Ghana	2006
Guatemala	2014
Guatemala	2011
Guatemala	2006
Guinea	2002
Haiti	2012
India	2011-2012
India	2009-2010
India	2007-2008
India	2006-2007
India	2005-2006
India	2004
India	2004-2005
India	2003
India	2002
India	2001-2002
India	2000-2001
India	1999-2000
India	1998
India	1997
India	1995-1996
India	1993
India	1993-1994
Iraq	2012
Kenya	2016
Kenya	2006
Liberia	2016
Liberia	2015
Liberia	2014
Malawi	2017
Malawi	2011
Malawi	2005
Maldives	2016
Maldives	2009
Micronesia, Federated States of	2014
Namibia	2003-2004
Namibia	1993-1994
Nauru	2013
Niger	2014
Palau	2014
Papua New Guinea	2009-2010
Romania	2011
Rwanda	2017
Rwanda	2014
Rwanda	2011
Solomon Islands	2013
Suriname	2016
Tajikistan	2009
Tanzania, United Republic of	2011-2012
Tanzania, United Republic of	2007
Tanzania, United Republic of	2000-2001
Togo	2015
Togo	2006
Tuvalu	2016
United Arab Emirates	2015
United States	2013
United States	2012
United States	2012-2013
United States	2011
United States	2011-2012
United States	2010
United States	2010-2011
United States	2009
United States	2009-2010
United States	2008
United States	2008-2009
United States	2007
United States	2007-2008
United States	2006
United States	2006-2007
United States	2005
United States	2004
United States	2003
United States	2002
Vanuatu	2010
Vanuatu	2006
Venezuela	2012
Viet Nam	2010-2011
")

allcons <- fread(
  "country	year
Zimbabwe	2005-2006
Zimbabwe	1999
Zambia	2017-2018
Zambia	2009
Zambia	2007
Zambia	2001-2002
Yemen, Rep.	2013
World	2013-2014
World	2009
World	2007-2008
World	2006
World	1995-2002
World	1989-2008
World	1955-2007
World	1955-2011
Vietnam	2006
Vietnam	2005
Vietnam	2004
Vietnam	2002
Vietnam	1997-1998
Vietnam	1992-1993
Vanuatu	2007-2010
Uzbekistan	2002
Ukraine	2007
Uganda	2020
Uganda	2018
Uganda	2018-2019
Uganda	2015
Uganda	2015-2016
Uganda	2014
Uganda	2013-2014
Uganda	2013
Uganda	2012
Uganda	2011
Uganda	2011-2012
Uganda	2010-2011
Uganda	2006
Uganda	2005-2010
Tonga	2007-2010
Timor-Leste	2009-2010
Timor-Leste	2007-2008
Timor-Leste	2001
Tanzania	2016
Tanzania	2014-2015
Tanzania	2013
Tanzania	2013-2016
Tanzania	2012-2013
Tanzania	2010
Tanzania	2010-2011
Tanzania	2009-2012
Tanzania	2009-2010
Tanzania	2008-2009
Tanzania	2008-2015
Tanzania	2008
Tanzania	2007-2008
Tanzania	2004
Tanzania	2003
Tanzania	1993-1994
Tanzania	1991-1994
Tajikistan	2018
Tajikistan	2016
Tajikistan	2015
Tajikistan	2013
Tajikistan	2012
Tajikistan	2007
Tajikistan	1999
Sudan	2014
Sri Lanka	2006
South Sudan	2017
South Sudan	2016
South Sudan	2016-2017
South Sudan	2015
South Sudan	2012-2014
South Africa	2016
South Africa	2015
South Africa	2014-2015
South Africa	2012
South Africa	2010-2011
South Africa	2010
South Africa	2008-2009
South Africa	2008
South Africa	2006
South Africa	2004
South Africa	2004-2005
South Africa	2002
South Africa	2002-2003
South Africa	2002-2005
South Africa	2000
South Africa	1999
South Africa	1993
South Africa	1993-1998
South Africa	1990-1991
Somalia	2017-2018
Somalia	2016
Somalia	2013
Sierra Leone	2017
Sierra Leone	2011
Sierra Leone	2003-2004
Serbia and Montenegro	2003
Serbia and Montenegro	2002
Serbia	2007
Senegal	2012
Rwanda	2016
Rwanda	2014
Rwanda	2012-2016
Romania	1977
Philippines	2012
Philippines	2003-2010
Philippines	1999
Philippines	1995
Peru	2011-2012
Peru	2008-2011
Pakistan	2017-2018
Pakistan	2012-2013
Pakistan	2004
Pakistan	2003
Pakistan	2003-2006
Pakistan	1991
Nigeria	2020-2021
Nigeria	2018-2020
Nigeria	2018-2019
Nigeria	2018
Nigeria	2017-2018
Nigeria	2016
Nigeria	2015
Nigeria	2015-2016
Nigeria	2014-2015
Nigeria	2013
Nigeria	2012-2013
Nigeria	2010-2011
Nigeria	2008
Niger	2018
Niger	2014-2015
Niger	2011-2012
Nicaragua	2007-2011
Nicaragua	1993
Nepal	2017
Nepal	2016
Nepal	2014
Nepal	2013
Nepal	2010-2011
Nepal	2006
Nepal	2003-2004
Nepal	1995-1996
Namibia	2013
Namibia	2009-2010
Namibia	2006-2007
Mozambique	2016
Mozambique	2015
Mozambique	2003
Mozambique	2002-2009
Morocco	2009-2010
Mongolia	2012-2013
Mali	2020
Mali	2006
Malawi	2020-2021
Malawi	2019-2020
Malawi	2016-2017
Malawi	2013
Malawi	2013-2014
Malawi	2012
Malawi	2010-2011
Malawi	2010-2013
Malawi	2010-2016
Malawi	2010-2019
Malawi	2010
Malawi	2008-2009
Malawi	2007-2008
Malawi	2004-2005
Madagascar	2016
Madagascar	2008-2009
Liberia	2016-2017
Liberia	2014-2015
Liberia	2010
Lesotho	2009-2010
Lao PDR	2006
Kyrgyz Republic	2005
Kyrgyz Republic	1998
Kyrgyz Republic	1997
Kyrgyz Republic	1996
Kyrgyz Republic	1993
Kosovo	2000
Kenya	2016
Kenya	2016-2018
Kenya	2014
Kenya	2012
Kenya	2010-2011
Kenya	2009-2010
Kenya	2009
Kenya	2006
Kenya	2005
Kenya	2004
Kazakhstan	2011-2012
Kazakhstan	1996
Jordan	2012
Jordan	2007
Jamaica	2000
Jamaica	1997
Jamaica	1996
Jamaica	1995
Jamaica	1994
Jamaica	1993
Jamaica	1992
Jamaica	1991
Jamaica	1990
Jamaica	1989
Jamaica	1989-1990
Jamaica	1988
Iraq	2018
Iraq	2017-2018
Iraq	2012-2013
Iraq	2006-2007
Indonesia	2012
Indonesia	2010-2012
Indonesia	2009
Indonesia	2009-2010
Indonesia	2008
Indonesia	2008-2009
Indonesia	2007-2008
Indonesia	2007
Indonesia	2002-2003
Indonesia	2000
Indonesia	1997-1998
Indonesia	1993-1994
Indonesia	1987
India	2020
India	2015-2016
India	2005-2006
Honduras	2017
Honduras	2012
Honduras	2008-2011
Guyana	2009
Guinea-Bissau	2000
Ghana	2017
Ghana	2014
Ghana	2009-2010
Ghana	2008
Ghana	2005-2006
Ghana	1998-1999
Ghana	1991-1992
Georgia	2020
Gambia	2015-2016
Gambia	2014-2015
Gambia	2010-2011
Europe and Central Asia	2006
Ethiopia	2020
Ethiopia	2018-2019
Ethiopia	2017
Ethiopia	2015-2016
Ethiopia	2013-2014
Ethiopia	2012
Ethiopia	2010-2011
Ethiopia	2010
Ethiopia	2009
Ethiopia	2005
Ethiopia	2004-2005
Ethiopia	1999-2000
Eswatini	2006-2007
Eritrea	2009
El Salvador	2011-2013
Egypt, Arab Rep.	2011-2012
Egypt, Arab Rep.	2011
Egypt, Arab Rep.	2008
Egypt, Arab Rep.	2005
Djibouti	2020
Côte d'Ivoire	2016
Côte d'Ivoire	1988-1989
Côte d'Ivoire	1987-1988
Côte d'Ivoire	1986-1987
Côte d'Ivoire	1985-1986
Congo, Rep.	2014
Colombia	2011
Colombia	2010
China	1995-1997
Chad	2020
Cameroon	2012
Cambodia	2020-2021
Cambodia	2005-2006
Burkina Faso	2020-2021
Burkina Faso	2014
Burkina Faso	2013-2014
Bulgaria	2014
Bulgaria	2011
Bulgaria	2010
Bulgaria	2007
Bulgaria	2001
Bulgaria	1997
Bulgaria	1995
Brazil	1996-1997
Bosnia-Herzegovina	2004-2005
Bosnia-Herzegovina	2003
Bosnia-Herzegovina	2002-2003
Bosnia-Herzegovina	2001
Benin	2018
Bangladesh	2019
Bangladesh	2018
Bangladesh	2016
Bangladesh	2009
Bangladesh	2007
Bangladesh	1998-1999
Azerbaijan	1995
Armenia	2018
Armenia	2016
Armenia	2015
Armenia	2014
Armenia	2013
Armenia	2012
Armenia	2011
Armenia	2010
Armenia	2010-2015
Armenia	2009
Armenia	2008
Armenia	2007-2008
Armenia	2007
Armenia	2006
Armenia	2005
Armenia	2004
Armenia	2003
Armenia	2002
Armenia	2001
Armenia	1996
Albania	2012
Albania	2008-2009
Albania	2008
Albania	2005
Albania	2004
Albania	2003
Albania	2002
Albania	1996
"
)


narrow_lsms <- 
  fread("
        TJK	2009
TJK	2009
TJK	2009
TJK	2009
TJK	2009
TJK	2009
TJK	2009
TJK	2009
TJK	2009
TJK	2009
TJK	2009
TJK	2009
TJK	2007
TJK	2007
TJK	2007
TJK	2007
TJK	2007
TJK	2007
TJK	2007
TJK	2007
TJK	2007
TJK	2007
TJK	2007
TJK	2007
TJK	2007
TJK	2007
TJK	2007
TJK	1999
SRB	2007
SRB	2007
SRB	2007
SRB	2007
SRB	2007
SRB	2003
SRB	2003
SRB	2003
SRB	2003
SRB	2003
SRB	2003
SRB	2003
SRB	2002
SRB	2002
SRB	2002
SRB	2002
SRB	2002
SRB	2002
SRB	2002
SRB	2002
SRB	2002
SRB	2002
SRB	2002
PER	1985
NIC	1993
NGA	2020
NGA	2020
NGA	2020
NGA	2020
NGA	2020
NGA	2020
NGA	2020
NGA	2020
NGA	2020
NGA	2020
NGA	2020
NGA	2020
NGA	2020
NGA	2020
NGA	2020
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2018
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2015
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2012
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NGA	2010
NER	2011
NER	2011
NER	2011
MWI	2020
MWI	2020
MWI	2020
MWI	2020
MWI	2020
MWI	2020
MWI	2020
MWI	2020
MWI	2020
MWI	2019
MWI	2019
MWI	2019
MWI	2019
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2016
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2019
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2010-2013-2016
MWI	2004
MWI	2004
KGZ	1993
BGR	2003
KSV	2000
KGZ	1998
KGZ	1998
KGZ	1998
KGZ	1998
KGZ	1998
KGZ	1993
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
BGR	2001
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2012
IRQ	2006
IRQ	2006
IRQ	2006
IRQ	2006
IRQ	2006
IRQ	2006
IRQ	2006
IRQ	2006
IRQ	2006
IRQ	2006
IRQ	2006
IRQ	2006
IRQ	2006
IRQ	2006
ETH	2020
ETH	2020
ETH	2020
ETH	2020
ETH	2020
ETH	2020
ETH	2020
ETH	2020
ETH	2020
ETH	2020
ETH	2020
ETH	2020
ETH	2018
ETH	2018
ETH	2018
ETH	2018
ETH	2018
ETH	2018
ETH	2018
ETH	2018
ETH	2015
ETH	2015
ETH	2015
ETH	2015
ETH	2015
ETH	2015
ETH	2013
ETH	2013
ETH	2013
ETH	2013
ETH	2013
ETH	2013
ETH	2013
ETH	2013
ETH	2013
ETH	2013
ETH	2013
ETH	2011
ETH	2011
ETH	2011
ETH	2011
ETH	2011
ETH	2011
ETH	2011
BIH	2004
BIH	2004
BIH	2004
BIH	2002
BIH	2002
BIH	2001
BIH	2001
BIH	2001
BIH	2001
BIH	2001
BIH	2001-2004
BIH	2001-2004
BIH	2001-2004
BIH	2001-2004
BIH	2001-2004
BIH	2001-2004
BIH	2001-2004
BIH	2001-2004
BIH	2001-2004
BIH	2001-2004
BIH	2001-2004
BIH	2001-2004
BIH	2001-2004
BIH	2001-2004
BGR	2007
BGR	2007
BGR	2007
BGR	2007
BGR	2007
BGR	2007
BGR	2007
BGR	2007
BGR	2007
BGR	2007
BGR	2007
BGR	2007
BGR	2003
BGR	2003
BGR	2003
BGR	2003
BGR	2003
BGR	2003
BGR	2001
BGR	2001
BGR	2001
BGR	2001
BGR	2001
BGR	2001
BGR	2001
BGR	2001
BGR	2001
BGR	2001
BGR	2001
BGR	2001
BGR	2001
BGR	1997
BGR	1997
BGR	1997
BGR	1995
BGR	2003
BGR	1995
BGR	1995
BGR	1995
ALB	2005
ALB	2005
ALB	2005
ALB	2005
ALB	2005
ALB	2005
ALB	2005
ALB	2005
ALB	2005
ALB	2004
ALB	2004
ALB	2003
ALB	2003
ALB	2003
ALB	2003
ALB	2003
ALB	2003
ALB	2003
ALB	2003
ALB	2002
ALB	2002
ALB	2002
ALB	2002
ALB	2002
ALB	2002")


# Summary of data availability --------------------------------------------

lmss <-
  setNames(split(lmss, seq(nrow(lmss))), lmss$country)
create_seq <- function(x) {
  y <- x$year %>% strsplit(., "-") %>%
    unlist %>%
    as.numeric
  
  if (length(y) > 1) {
    start <- y[1]
    end <- y[2]
    
    y <- mapply(function(x, y)
      seq(x, y), start, end) %>%
      unlist %>%
      as.numeric
  }
  CJ(country = x$country, year = y)
}

lmss <- lapply(lmss, create_seq)

lmss <- rbindlist(lmss) %>% as.data.table()

lmss[, count := 1]

# Library
library(ggplot2)

# Dummy data
x <- LETTERS[1:20]
y <- paste0("var", seq(1, 20))
data <- expand.grid(X = x, Y = y)
data$Z <- runif(400, 0, 5)

lmss$region <-
  lmss$country %>% countrycode(., "country.name", "region")
lmss <- lmss[!is.na(region), ]
lvls <-
  unlist(lmss[order(region, decreasing = T), .(country)]) %>% as.vector %>% unique
lmss[, country := factor(country, levels = lvls)]

lmss[, rnum := random::randomNumbers(
  n = nrow(lmss),
  min = 1,
  max = 1000,
  col = 1
)]
lmss <- lmss[order(rnum)]
# Heatmap
heat <-
  ggplot(lmss[year >= 2000 &
                order(region)], aes(year, country, fill = region)) +
  geom_tile() +
  theme(
    legend.background = element_blank(),
    legend.title = element_blank(),
    axis.text.x = element_text(angle = 90, vjust = -1),
    panel.grid.minor.x = element_line(
      color = "gray72",
      size = 0.1,
      linetype = "dotted"
    ),
    panel.grid.major.x = element_line(
      color = "gray72",
      size = 0.1,
      linetype = "dotted"
    ),
    panel.grid.minor.y = element_line(
      color = "gray72",
      size = 0.1,
      linetype = "dotted"
    ),
    panel.grid.major.y = element_line(
      color = "gray72",
      size = 0.1,
      linetype = "dotted"
    )
  ) +
  scale_x_binned(n.breaks = 21)

setwd("C:/Users/user/Dropbox/Charts/HF_measures/input")
ggsave(
  "consumption_surveys_LMSS_micro.png",
  heat,
  width = 10,
  height = 4,
  limitsize = FALSE
)

