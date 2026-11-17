library(dplyr)
library(ggplot2)

results <- read.csv("results/full_precision.csv")
models <- read.csv("results/model_summary.csv")
plot_data <- results %>%
  filter(outcome %in% c("spending_infl", "inp_infl", "out_infl"),
         term != "(Intercept)") %>%
  left_join(models %>% select(outcome, clusters), by = "outcome") %>%
  mutate(
    plan = factor(term,
      levels = rev(c("rand_plan_group2", "rand_plan_group3", "rand_plan_group4",
                     "rand_plan_group6", "rand_plan_group5")),
      labels = rev(c("25%", "Mixed", "50%", "Individual deductible", "95%"))),
    outcome_label = factor(outcome,
      levels = c("spending_infl", "inp_infl", "out_infl"),
      labels = c("Total spending", "Inpatient spending", "Outpatient spending")),
    lower = estimate - qt(0.975, clusters - 1) * standard_error,
    upper = estimate + qt(0.975, clusters - 1) * standard_error
  )

p <- ggplot(plot_data, aes(x = estimate, y = plan)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_segment(aes(x = lower, xend = upper, yend = plan), linewidth = 0.6) +
  geom_point(size = 2.5) +
  facet_wrap(~ outcome_label, nrow = 1) +
  scale_x_continuous(limits = c(-1300, 650), breaks = c(-1000, -500, 0, 500)) +
  labs(x = "Difference from free care (2011 USD per person-year)", y = NULL,
       title = "Cost sharing and annual medical spending",
       subtitle = "Table 2 estimates and pointwise 95% confidence intervals",
       caption = "Family-clustered standard errors; t critical value with 3,208 df. All models use 20,203 person-years.") +
  theme_bw(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank(), strip.background = element_blank(),
        plot.caption = element_text(hjust = 0))
write.csv(plot_data, "results/table2_confidence_intervals.csv", row.names = FALSE)
ggsave("results/table2_coefficients.png", p, width = 12, height = 5, dpi = 180)
ggsave("results/table2_coefficients.pdf", p, width = 12, height = 5)

