library(data.table)

df <-
  read_excel(
    "C:/Users/gyang/Dropbox/CGD GlobalSat/HF_measures/input/manual_reproduce_henderson_pre2013.xlsx",
    sheet = 2
  ) %>% as.data.table()

df[, `log(WDI)` := log(WDI / shift(WDI)), by = iso3c]
df <- df[, .(iso3c, year, `log(Oxford)`, `log(sumpix)`, `log(WDI)`)]

fit <- lm(`log(WDI)` ~ `log(sumpix)` + iso3c + factor(year),
          data = na.omit(df)[!(iso3c %in% c("LBY", "IRQ", "CAF", "LBR"))])
summary(fit)
# fit %>% lm.ass

s <- fit %>% broom::augment()
s <- as.data.table(s)
s <- s[order(-abs(s$.cooksd))]
s


bob <- fread("Nighttime_Lights_ADM2_1992_2013.csv")
bob <- bob[, .(iso3c = countrycode, year, mean_light, sum_light)]
wdi <- wb_data("NY.GDP.MKTP.KN") %>% as.data.table()
wdi <-
  wdi[, .(iso3c, year = date, wbgdp = NY.GDP.MKTP.KN)] %>% na.omit
bob <- merge(bob, wdi, by = c("iso3c", "year"), all.x = T)

bob <- bob[, .(sum_light = sum(sum_light, na.rm = T),
        wbgdp = mean(wbgdp, na.rm=T)), by = .(iso3c, year)] %>% 
  na.omit() %>% as.data.table()

bob$year %>% sort %>% table

bob[,ln_wbgdp:=log(wbgdp/shift(wbgdp)), by = iso3c]
bob[,ln_sumlight:=log(sum_light/shift(sum_light)), by = iso3c]
fit <- lm(ln_wbgdp~ln_sumlight + iso3c + factor(year), data = bob[year<=2008])
fit %>% summary()

bob %>% write.csv("henderson_pre2013_ntl_wb_gdp.csv")







