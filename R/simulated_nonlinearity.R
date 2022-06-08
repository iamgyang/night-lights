sim_df <- data.table(gdp = seq(0, 100000))

# suppose the true relationship is quadratic
sim_df[, light := gdp - 0.000009 * gdp ^ 2 + runif(nrow(sim_df)) * 0.1 * gdp]
plot <- ggplot(sim_df, aes(x = gdp, y = light)) + geom_point()
ggsave("true_rel.pdf", plot)

# now, suppose we have a bunch of countries that are each at different GDP per capita levels:
sim_df[, country := gdp %% 100]
sim_df[country == 0, new_country := 1]
sim_df[, country := cumsum(ifelse(is.na(new_country), 0, new_country)) + new_country * 0]
sim_df[, country := as.character(nafill(country, "locf"))]
sim_df[, new_country := NULL]

library(fixest)
summary(feols(light ~ gdp + I(gdp^2) | country, data = sim_df))
summary(feols(gdp ~ light + light:gdp, data = sim_df))
