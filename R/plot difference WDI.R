bob <- rio::import("C:/Users/user/Dropbox/CGD GlobalSat/HF_measures/input/clean_validation_base.dta") %>% dfdt()

plot <-
ggplot(
bob %>% filter(g_ln_WDI <= 0.2 &
g_ln_WDI >= -0.2),
aes(y = g_ln_del_sum_pix_area, x = g_ln_WDI)
) + geom_point() + geom_smooth(method = 'loess', se = F) +
ylab('Change in Log Lighs / Area') + xlab('Change in Log GDP WDI') +
ylim(c(-3, 3)) + xlim(-0.25, 0.25) + ggtitle('Difference WDI:NTL') +
geom_vline(xintercept = 0) + geom_hline(yintercept = 0) + my_custom_theme + geom_smooth(data = bob %>% filter(g_ln_WDI <
0),
aes(y = g_ln_del_sum_pix_area, x = g_ln_WDI)) + geom_smooth(data = bob %>% filter(g_ln_WDI >
0),
aes(y = g_ln_del_sum_pix_area, x = g_ln_WDI))

ggsave("difference WDI NTL.png", plot, width = 7.5, height = 6)