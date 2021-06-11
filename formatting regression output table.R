# transforming natl_reg_hender_5
setwd("C:/Users/gyang/Dropbox/CGD GlobalSat/HF_measures/input")
bob <- fread("natl_reg_hender_10.txt") %>% as.matrix() %>% t()
bob <- bob %>% as.data.table()
bob[grepl("quart", V2) , Temporal := "quart"]
bob[grepl("year", V2) , Temporal := "year"]
bob[grepl("month", V2) , Temporal := "month"]
bob[grepl("gid_2", V2) , Spatial := "gid_2"]
bob[grepl("iso3c", V2) , Spatial := "iso3c"]
bob <- as.data.frame(bob)
bob <- bob[, c((ncol(bob)-1):(ncol(bob)), 
               1:(ncol(bob) - 2))] %>% as.data.table()
bob[is.na(Temporal), Temporal := "Overall"]
bob <- split(bob, bob$Temporal)
sal <- rbindlist(lapply(bob[names(bob) != "Overall"], function(x)
    as.data.table(t(x))), fill = T)
left_col <- bob$Overall %>% t
left_col <- left_col[,1]
left_col[1:2] <- c("Temporal","Spatial")
bob <- cbind(rep(left_col, 3), sal)
bob <- bob[V2!=""]
bob <- as.matrix(bob)

todel1 <- apply(bob, 2, nchar) %>% as.data.table()
todel1[,d:=apply(.SD, 1, function(x) sum(x==4|x==3))]
todel1 <- as.data.frame(todel1)
todel1 <- todel1$d==8

todel2 <- 
    apply(bob, 2, function(x) grepl("\\(",x)) %>% 
    as.data.table()
todel2[,d:=apply(.SD, 1, function(x) sum(x))]
todel2 <- as.data.frame(todel2)
todel2 <- todel2$d==8

todel <- todel1 & todel2

bob <- bob[!todel,]
bob %>% write.csv("formatted_regression_initial2.csv")

###########################################################################
###########################################################################
# transforming natl_reg_hender_5
setwd("C:/Users/gyang/Dropbox/CGD GlobalSat/HF_measures/input")
bob <- fread("natl_reg_hender_18.txt") %>% as.matrix() %>% t()
bob <- bob %>% as.data.table()
bob[grepl("quart", V2) , Temporal := "quart"]
bob[grepl("year", V2) , Temporal := "year"]
bob[grepl("month", V2) , Temporal := "month"]
bob[grepl("none_none", V2) , Temporal := "none"]
bob[grepl("none_none", V2) , Spatial := "none"]
bob[grepl("gid_2", V2) , Spatial := "gid_2"]
bob[grepl("iso3c", V2) , Spatial := "iso3c"]
bob <- as.data.frame(bob)
bob <- setDT(bob)[(Temporal=="month" & Spatial == "gid_2") | (Temporal=="none" & Spatial == "none")]
bob %>% write.csv("formatted_regression_initial5.csv")

