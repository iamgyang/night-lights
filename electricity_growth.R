library("WDI"); library("ggplot2"); library("ggthemes"); library("scales")


WDIsearch()
elec <- WDI(country = "all", indicator = c("EG.ELC.ACCS.ZS",      # Access to electricity
                                         "EG.USE.ELEC.KH.PC"),   # Electricity consumption 
          start = 1992, end = 2020, extra = FALSE, cache = NULL)

View(elec)
length(unique(elec$country))
# ========================================================================================








# Global values
# ========================================================================================
world <- elec[elec$country == "World",]

# global_elec <-  elec[,.(geacs = mean(EG.ELC.ACCS.ZS, na.rm=T),
#                         gecon = sum(EG.USE.ELEC.KH.PC, na.rm=T)), by=.(year)]
# View(global_elec)


glec_1 <- world[world$year < 2020,]
names(glec_1)[names(glec_1) == "EG.ELC.ACCS.ZS"] <- "geacs"
names(glec_1)[names(glec_1) == "EG.USE.ELEC.KH.PC"] <- "gecon"


ggplot(glec_1, aes(y=geacs, x=year)) + geom_line() +
  geom_vline(xintercept = 1992, linetype='dotted', color='blue', size=1) + 
  geom_vline(xintercept = 2008, linetype='dotted', color='blue', size=1) + 
  geom_vline(xintercept = 2012, linetype='dotted', color='red', size=1) +
  geom_vline(xintercept = 2020, linetype='dotted', color='red', size=1) +
  scale_x_continuous(breaks=seq(1992, 2020, 1))+ ggtitle('Global access to electricity ') +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) 
  

ggplot(glec_1, aes(y=gecon, x=year)) + geom_line() +
  geom_vline(xintercept = 1992, linetype='dotted', color='blue', size=1) + 
  geom_vline(xintercept = 2008, linetype='dotted', color='blue', size=1) + 
  geom_vline(xintercept = 2012, linetype='dotted', color='red', size=1) +
  geom_vline(xintercept = 2020, linetype='dotted', color='red', size=1) +
  scale_x_continuous(breaks=seq(1992, 2020, 1))+ ggtitle('Global electricity consumption ') +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) 



# create a balance panel 
# ========================================================================================
elec <- data.table(elec)
nacs <- elec[is.na(elec$EG.ELC.ACCS.ZS)]
table(nacs$year)
nacn <- elec[is.na(elec$EG.USE.ELEC.KH.PC)]
table(nacn$year)

# choose only countries which have data all across
acbal <- elec[!is.na(elec$EG.ELC.ACCS.ZS) & !is.na(elec$EG.ELC.ACCS.ZS),]

library(plm)
acdt <- elec
acdt$EG.USE.ELEC.KH.PC <- NULL
acdt <- data.frame(acdt)
# Select countries with data for all years
bal1 <- acdt[!is.na(acdt$EG.ELC.ACCS.ZS),] 
table(bal1$country)
table(bal1$year)

acbal <- make.pbalanced(as.data.frame(acdt),index = c("country","year")) 
# ========================================================================================
