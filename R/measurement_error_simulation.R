closeAllConnections()
# on measurement error:

# suppose this is our TRUE night lights data:
set.seed(385047)
ntl <- rgamma(n = 980, shape = 1, scale = 2)
ntl <- c(ntl, rep(100, 20))
hist(ntl,50)

# and this is our error:
error <- rnorm(1000)
# error <- runif(1000)
# error <- rgamma(n = 1000, shape = 2, scale = 2)
hist(error, 50)

# so this is what's observed
viirs <- ntl+error; hist(viirs, 50)
dmsp <- ifelse(ntl+error>5,5,ntl+error); hist(dmsp, 50)

# and this is our TRUE relationship between lights and GDP
gdp <- 0.3*ntl; hist(gdp, 50)

# merge it all together:
DT <- data.table(
    country = as.vector(unlist(random::randomNumbers(1000, 1, 50, 1))),
    gdp = gdp,
    error = error,
    dmsp = dmsp,
    viirs = viirs
)

# and we aggregate values up by country:
DT[,viirs_country:=sum(viirs, na.rm = T), by = .(country)]
DT[,dmsp_country:=sum(dmsp, na.rm = T), by = .(country)]
DT[,gdp_country:=sum(gdp, na.rm = T), by = .(country)]
DT[,polygon_area:=length(viirs), by = .(country)]
DT[,lights_area_dmsp:=dmsp_country/polygon_area]
DT[,lights_area_viirs:=viirs_country/polygon_area]

# and we run a regression
summary(lm(gdp~lights_area_viirs, data = DT))
summary(lm(gdp~lights_area_dmsp, data = DT))

plot(log(DT$lights_area_dmsp)~log(DT$lights_area_viirs))
abline(0,1)
closeAllConnections()