# Note: I had to do this in R, because otherwise in STATA it would take several 
# days to complete.

rm(list = ls()) # clear the workspace
# Options: ----------------------------------------------------------------

# debugging
options(error=browser)
options(error=NULL)

# disable data.table auto-indexing (causes errors w/ dplyr functions)
options(datatable.auto.index = FALSE)

# Directories -------------------------------------------------------------

# You will have to edit this to be your own computer's working directories:
user <- Sys.info()["user"]
root_dir <- paste0("C:/Users/", user, "/Dropbox/CGD GlobalSat/HF_measures/")
input_dir <- paste0(root_dir, "input")
output_dir <- paste0(root_dir, "output")
code_dir <- paste0(root_dir, "code")
raw_dir <- paste0("C:/Users/", user, "/Dropbox/CGD GlobalSat/raw_data/")
setwd(input_dir)

# Packages ---------------------------------------------------------------
list.of.packages <- c("data.table", "dplyr", "stringdist", "countrycode", "ggplot2", 
                      "ggthemes", "readxl", "tidyr", "glue", "fst", "readstata13")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages)) install.packages(new.packages, dependencies = TRUE)
for (package in list.of.packages) {library(eval((package)), character.only = TRUE)}

# set GGPLOT default theme:
theme_set(theme_clean() + theme(plot.background = element_rect(color = "white")))

# load personal functions
source(paste0("C:/Users/", user, "/Dropbox/Coding_General/personal.functions.R"))


###########################################################################
# THIS IS WHERE THE ACTUAL CODE BEGINS
###########################################################################

# Import night lights
setwd(input_dir)
ntl <- readstata13::read.dta13("iso3c_year_viirs_new.dta") %>% as.data.table()

# shaded region on plot:
rects <- data.frame(xstart = 2012, xend = 2013)

# make graph of CAF
plot <- ggplot(ntl[iso3c == "CAF"], aes(x = year, y = del_sum_pix)) + 
  geom_rect(aes(xmin = 2012, xmax = 2013, ymin = 0, ymax = Inf),fill = "grey78", alpha = 0.1) + 
  geom_line(size = 1) + 
  my_custom_theme + 
  labs(x = "Year",y = "Sum of Pixels\n(Lights in Central African Republic)") + 
  scale_color_colorblind() + 
  scale_x_continuous(breaks = c(c(2012, 2013), seq(2013, 2020, 3))) + 
  scale_y_continuous(expand = c(0, 0)) + 
  theme(legend.position = "none") + 
  theme(panel.grid = element_blank(),
        panel.border = element_blank())


ggsave("lights_didnt_drop_CAF.png", plot, width = 7,height = 4)

# make graph of Yemen
plot <- ggplot(ntl[iso3c == name2code("yemen")], aes(x = year, y = del_sum_pix)) + 
  geom_rect(aes(xmin = 2014, xmax = 2020, ymin = 0, ymax = Inf),fill = "grey78", alpha = 0.1) + 
  geom_line(size = 1) + 
  my_custom_theme + 
  labs(x = "Year",y = "Sum of Pixels\n(Lights in Yemen)") + 
  scale_color_colorblind() + 
  scale_x_continuous(breaks = seq(2012, 2020, 2)) + 
  scale_y_continuous(expand = c(0, 0)) + 
  theme(legend.position = "none") + 
  theme(panel.grid = element_blank(),
        panel.border = element_blank())

ggsave("lights_did_drop_YEM.png", plot, width = 7,height = 4)