# get DMSP from AIDDATA

bob <-
  fread(
    "C:/Users/gyang/Downloads/merge_Admin2_NTL_2020.csv dmsp/merge_Admin2_NTL_2020.csv"
  )
bob <- bob %>%
  dplyr::select(ends_with("sum") |
                  all_of(c("OBJECTID", "pol_area", "GID_0", "GID_1", "GID_2")))
names(bob) <-
  names(bob) %>% gsub("v4composites_calibrated_201709.", "", ., fixed = T)
names(bob) <- names(bob) %>% gsub(".sum", "", ., fixed = T)
bob <- bob %>% 
  pivot_longer(as.character(seq(1992, 2013))) %>%
  rename(year = name,
         sum_pix_dmsp_ad = value) %>%
  as.data.table()
bob %>% write.csv(
  "C:/Users/gyang/Dropbox/CGD GlobalSat/raw_data/DMSP ADM2/dmsp 1992-2013.csv",
  na = "",
  row.names = FALSE
)
#######################
# get geomapping from parth
load("C:/Users/gyang/Dropbox/CGD GlobalSat/raw_data/National Accounts/geo_coded_data/global_subnational_ntlmerged_woPHL.RData")
vrsmn_adm1_grp <- as.data.table(vrsmn_adm1_grp)
unique(vrsmn_adm1_grp[, .(year, region = tolower(region), iso3c = iso3c.x, gid_1)]) %>%
  write.csv(
    "C:/Users/gyang/Dropbox/CGD GlobalSat/raw_data/National Accounts/geo_coded_data/global_subnational_ntlmerged_woPHL.csv",
    na = "",
    row.names = FALSE
  )