bob <- readstata13::read.dta13("C:/Users/user/Dropbox/CGD GlobalSat/HF_measures/input/angrist_replication_with_new_data.dta") %>% as.data.table()

id.vars.ntl <- c('iso3c', 'ln_PWT', 'ln_start_gdppc_pwt')
bob <- melt(bob,
     id.vars = id.vars.ntl,
     measure.vars = setdiff(names(bob), id.vars.ntl))
bob[, variable:= gsub("g_ln_","",variable)]
bob[variable=='sum_pix',variable:='Lights']
bob[variable=='del_sum_pix',variable:='Lights Negatives Removed']

theme_set(
    theme_clean() + theme(
        plot.background = element_rect(color = "white"),
        axis.text.x = element_text(angle = 90),
        legend.title = element_blank()
    )
)


plot1 <- ggplot(bob) +
    geom_point(aes(x = exp(ln_start_gdppc_pwt), y = value, 
                   group = variable, color = variable)) +
    geom_smooth(
        aes(x = exp(ln_start_gdppc_pwt), y = value,
            group = variable, color = variable),
        stat = "smooth",
        position = "identity",
        method = "lm"
    ) +
    scale_x_continuous(
        trans = "log10",
        labels = scales::dollar_format(),
        breaks = c(seq(1000, 150000, 30000)),
        limits = c(800, 150000)
    ) +
    labs(x = "GDP per capita (PWT) 2012", 
         y = "Growth") + 
    facet_wrap(~ variable) + 
    scale_color_colorblind() + 
    theme(legend.background = element_blank(),
          legend.position = "top",
          legend.justification = c("left", "top"),
          legend.box.just = "left",
          legend.key.size = unit(.5, "line"),
          axis.title.y = element_text(
              angle = 0,
              vjust = 0.5,
              hjust = 1,
              size = 12
          ),
          axis.title.x = element_text(
              size = 12
          ))

    

ggsave("angrist_alt_plot.png", plot1, width = 10, height = 7, limitsize = FALSE,
       dpi = 1000)
