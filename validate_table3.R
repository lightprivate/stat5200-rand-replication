library(foreign)
library(dplyr)

d <- read.dta("data/person_years.dta", convert.factors = FALSE)
fits <- readRDS("results/table3_models.rds")
reported <- read.csv("results/table3_panelA_full_precision.csv")
checks <- list()

# Direct cluster-score calculation, independent of vcovCL().
for (key in names(fits)) {
  fit <- fits[[key]]
  X <- model.matrix(fit)[, !is.na(coef(fit)), drop = FALSE]
  n <- nrow(X)
  k <- ncol(X)
  G <- n_distinct(d$ifamily)
  scores <- rowsum(X * residuals(fit), group = d$ifamily)
  bread <- solve(crossprod(X))
  V <- G / (G - 1) * (n - 1) / (n - k) * bread %*% crossprod(scores) %*% bread
  row <- reported[paste(reported$specification, reported$outcome, sep = "_") == key, ]
  se <- sqrt(V["plan5", "plan5"])
  checks[[key]] <- data.frame(model = key, direct_se = se,
                              saved_se = row$standard_error,
                              absolute_difference = abs(se - row$standard_error))
}
checks <- bind_rows(checks)
stopifnot(max(checks$absolute_difference) < 1e-7)

baseline <- read.csv("results/full_precision.csv") %>%
  filter(term == "rand_plan_group5") %>% select(outcome, estimate, standard_error)
check_baseline <- reported %>% filter(specification == 1) %>%
  left_join(baseline, by = "outcome", suffix = c("", "_table2"))
stopifnot(max(abs(check_baseline$estimate - check_baseline$estimate_table2)) < 1e-8,
          max(abs(check_baseline$standard_error - check_baseline$standard_error_table2)) < 1e-8,
          sum(d$rand_plan_group %in% c(1, 5)) == 10564)

# Verify the authors' sequential expenditure adjustment from original values.
multiplier <- c(1.04, 1.06, 1.06, 1.06, 1.14, 1.11)[d$rand_plan_group]
adjusted_total <- model.response(model.frame(fits[["2_spending_infl"]]))
expected <- d$spending_infl + d$out_infl * multiplier * (multiplier - 1)
stopifnot(max(abs(adjusted_total - expected)) < 1e-8)
write.csv(checks, "results/table3_independent_validation.csv", row.names = FALSE)
cat("PASS: all 18 clustered SEs independently verified; baseline and adjustment checks passed.\n")

