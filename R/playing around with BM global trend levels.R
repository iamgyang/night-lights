rm(list = ls())
load("C:/Users/gyang/Downloads/BM_ctyrmn_12-21.RData")
DT <- as.data.table(bm_ctyrmn)
DT[,ln_BM_sumpix:=log(BM_sumpix)]
fit <- lm(ln_BM_sumpix~mon, DT[is.finite(ln_BM_sumpix)])
DT$r_lights <- predict(fit, DT)
DT$r_lights <- DT$ln_BM_sumpix - DT$r_lights
DT <- DT[,.(r_lights = sum(r_lights)), by = .(mon, year)]
user <- "gyang"
source(paste0("C:/Users/", user, "/Dropbox/Coding_General/personal.functions.R"))
DT[,date:=mdy(paste(mon, "-01-", year))]
ggplot(DT, aes(y = r_lights, x = date)) + geom_line() + my_custom_theme
