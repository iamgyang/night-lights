load(
  "C:/Users/gyang/Dropbox/CGD GlobalSat/intermediate_data/adm0-annual/VIIRSmon_GDP_adm0ann.RData"
)
vrsmn_adm0_ann <- rename(vrsmn_adm0_ann, PWT = pwt_rgdpna)
setnames(vrsmn_adm0_ann,
         setdiff(names(vrsmn_adm0_ann), c("iso3c", "year")),
         paste0(setdiff(
           names(vrsmn_adm0_ann), c("iso3c", "year")
         ), "_pagg"))
vrsmn_adm0_ann %>% readstata13::save.dta13(
  "C:/Users/gyang/Dropbox/CGD GlobalSat/intermediate_data/adm0-annual/vrsmn_adm0_ann_2.dta"
)