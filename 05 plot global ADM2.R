

setwd("C:/Users/gyang/Dropbox/CGD GlobalSat/HF_measures/input")

df <-
  readstata13::read.dta13("adm2_month_derived.dta") %>% as.data.table()
df <- df[year >= 2018 & year <= 2020]
df[month >= 3, period := "Covid-19"]
df[month < 3, period := "pre-Covid-19"]

# df <- df %>%
#   group_by(period, year) %>%
#   slice_sample(prop = 0.05) %>%
#   as.data.table()

# degree 1 on LHS and degree 5 on RHS

df <- df[is.finite(ln_sum_pix_area) & !is.na(ln_sum_pix_area)]

set.seed(1000)
plot <- ggplot() +
  geom_point(data = df,
             aes(x = jitter(month, amount = 0.4), y = ln_sum_pix_area),
             alpha = 0.001, shape = 1
             ) +
  geom_smooth(
    data = df[period == "Covid-19"],
    aes(
      x = jitter(month, amount = 0.4),
      y = ln_sum_pix_area,
      group = as.factor(year),
      color = as.factor(year),
    ),
    se = FALSE,
    formula = y ~ poly(x, 5)
  ) +
  geom_smooth(
    data = df[period == "pre-Covid-19"],
    aes(
      x = jitter(month, amount = 0.4),
      y = ln_sum_pix_area,
      group = as.factor(year),
      color = as.factor(year)
    ),
    se = FALSE,
    formula = y ~ poly(x, 1)
  ) +
  my_custom_theme +
  labs(x = "month", subtitle = "Log Lights / Area", y = "") +
  scale_x_continuous(breaks = seq(1, 12, 1), limits = c(0, 13)) +
  scale_y_continuous(breaks = seq(-10, 10, 0.5), limits = c(-10, 10)) +
  coord_cartesian(xlim = c(0, 13), ylim = c(0, 2)) +
  scale_color_stata() +
  guides(colour = guide_legend(override.aes = list(size = 3)))


ggsave("plot_poly_pre_post_linear_fit_jan_feb.png",
       plot,
       width = 6,
       height = 5)

# degree 5 polynomial on discontinuity

set.seed(1000)
plot <- ggplot() +
  geom_point(data = df,
             aes(x = jitter(month, amount = 0.4), y = ln_sum_pix_area),
             alpha = 0.001, shape = 1
  ) +
  geom_smooth(
    data = df[period == "Covid-19"],
    aes(
      x = jitter(month, amount = 0.4),
      y = ln_sum_pix_area,
      group = as.factor(year),
      color = as.factor(year),
    ),
    se = FALSE,
    formula = y ~ poly(x, 5)
  ) +
  geom_smooth(
    data = df[period == "pre-Covid-19"],
    aes(
      x = jitter(month, amount = 0.4),
      y = ln_sum_pix_area,
      group = as.factor(year),
      color = as.factor(year)
    ),
    se = FALSE,
    formula = y ~ poly(x, 5)
  ) +
  my_custom_theme +
  labs(x = "month", subtitle = "Log Lights / Area", y = "") +
  scale_x_continuous(breaks = seq(1, 12, 1), limits = c(0, 13)) +
  scale_y_continuous(breaks = seq(-10, 10, 0.5), limits = c(-10, 10)) +
  coord_cartesian(xlim = c(0, 13), ylim = c(0, 2)) +
  scale_color_stata() +
  guides(colour = guide_legend(override.aes = list(size = 3)))


ggsave("plot_poly_pre_post_poly5_fit_jan_feb.png",
       plot,
       width = 6,
       height = 5)



# degree 7 polynomial on all data

set.seed(1000)
plot <- ggplot() +
  geom_point(data = df,
             aes(x = jitter(month, amount = 0.4), y = ln_sum_pix_area),
             alpha = 0.001, shape = 1
  ) +
  geom_smooth(
    data = df,
    aes(
      x = jitter(month, amount = 0.4),
      y = ln_sum_pix_area,
      group = as.factor(year),
      color = as.factor(year),
    ),
    se = FALSE,
    formula = y ~ poly(x, 7)
  ) +
  my_custom_theme +
  labs(x = "month", subtitle = "Log Lights / Area", y = "") +
  scale_x_continuous(breaks = seq(1, 12, 1), limits = c(0, 13)) +
  scale_y_continuous(breaks = seq(-10, 10, 0.5), limits = c(-10, 10)) +
  coord_cartesian(xlim = c(0, 13), ylim = c(0, 2)) +
  scale_color_stata() +
  guides(colour = guide_legend(override.aes = list(size = 3)))


ggsave("plot_poly_pre_post_poly7_all.png",
       plot,
       width = 6,
       height = 5)





# box plot

set.seed(1000)
plot <- 
  ggplot() +
  geom_boxplot(data = df,
               aes(x = as.factor(month),
                   y = ln_sum_pix_area, 
                   group = interaction(month, year),
                   color = as.factor(year)
               ))+
  my_custom_theme +
  labs(x = "month", subtitle = "Log Lights / Area", y = "") +
  scale_color_stata()

ggsave("plot_box_pre_post_poly7_all.png",
       plot,
       width = 6,
       height = 5)





#  box plot zoomed out

set.seed(1000)
plot <- 
  ggplot() +
  geom_boxplot(data = df,
               aes(x = as.factor(month),
                   y = ln_sum_pix_area, 
                   group = interaction(month, year),
                   color = as.factor(year)
               ))+
  my_custom_theme +
  labs(x = "month", subtitle = "Log Lights / Area", y = "") +
  scale_y_continuous(breaks = seq(-10, 10, 0.5), limits = c(-10, 10)) +
  coord_cartesian(xlim = c(0, 13), ylim = c(0, 2)) +
  scale_color_stata()

ggsave("plot_box_pre_post_poly7_all_zoomed_out.png",
       plot,
       width = 6,
       height = 5)
