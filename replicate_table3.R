# Table 3, Panel A, rows 1-3: six level/any-spending columns.
library(foreign)
library(dplyr)
library(broom)
library(sandwich)
source("table_output.R")
dir.create("results", showWarnings = FALSE)

d <- read.dta("data/person_years.dta", convert.factors = FALSE) %>%
  mutate(plan = factor(rand_plan_group, levels = 1:6),
         site_month = factor(paste(site, fam_start_month, sep = "_")),
         start_year = factor(fam_start_year))
contrasts(d$plan) <- contr.treatment(6, base = 1)
contrasts(d$site_month) <- contr.treatment(nlevels(d$site_month))
contrasts(d$start_year) <- contr.treatment(nlevels(d$start_year))

# Preserve the authors' multipliers and sequential updates (tables.do, step 8).
adjusted <- d %>% mutate(
  multiplier = c(1.04, 1.06, 1.06, 1.06, 1.14, 1.11)[rand_plan_group],
  out_infl = out_infl * multiplier,
  spending_infl = spending_infl + out_infl * (multiplier - 1),
  any_out = any_out * multiplier,
  any_spending = any_spending * multiplier
)

covariates <- c(
  "hosp", "hosp_missing", "havemd", "havemd_missing", "mdexam", "mdexam_missing",
  "mdvis", "mdvis_missing", "log_mdexp", "log_mdexp_missing",
  "any_d_routine", "any_d_routine_missing", "any_d_special", "any_d_special_missing",
  "female", "age_6to17", "age_18to44", "age_45plus", "white", "white_missing",
  "hs_grad", "more_than_hs", "educ_missing", "city_backgrnd", "suburb_backgrnd",
  "town_backgrnd", "backgrnd_missing", "log_fam_income", "log_fam_income_sq",
  "fam_income_missing", "any_working_fam", "any_working_fam_missing", "insured",
  "insured_missing", "workins", "workins_missing", "privins", "privins_missing",
  "publins", "publins_missing", "exc_health", "good_health", "health_status_missing",
  "has_pain", "has_pain_missing", "has_worry", "has_worry_missing"
)
# Match the missing-value convention; centering does not change plan contrasts.
for (v in covariates) {
  adjusted[[v]][is.na(adjusted[[v]])] <- -1
  adjusted[[v]] <- adjusted[[v]] - mean(adjusted[[v]])
}
formulas <- list(
  any_spending = any_spending ~ plan + site_month + start_year,
  spending_infl = spending_infl ~ plan + site_month + start_year,
  any_inp = any_inp ~ plan + site_month + start_year,
  inp_infl = inp_infl ~ plan + site_month + start_year,
  any_out = any_out ~ plan + site_month + start_year,
  out_infl = out_infl ~ plan + site_month + start_year
)
results <- list()
fits_table3 <- list()
G <- n_distinct(d$ifamily)
for (specification in 1:3) {
  analysis_data <- if (specification == 1) d else adjusted
  for (y in names(formulas)) {
    formula <- formulas[[y]]
    if (specification == 3) {
      formula <- reformulate(c("plan", "site_month", "start_year", covariates), y)
    }
    fit <- lm(formula, data = analysis_data)
    V <- vcovCL(fit, cluster = analysis_data$ifamily, type = "HC1", cadjust = TRUE)
    result <- tidy(fit) %>% filter(term == "plan5") %>% select(term, estimate)
    result <- result %>% mutate(
      specification = specification, outcome = y,
      standard_error = sqrt(V["plan5", "plan5"]),
      lower = estimate - qt(0.975, G - 1) * standard_error,
      upper = estimate + qt(0.975, G - 1) * standard_error,
      model_N = nobs(fit), rank = fit$rank, family_clusters = G
    )
    stopifnot(nobs(fit) == 20203, G == 3209, nrow(result) == 1, is.finite(result$estimate))
    key <- paste(specification, y, sep = "_")
    results[[key]] <- result
    fits_table3[[key]] <- fit
  }
}
results <- bind_rows(results)
write.csv(results, "results/table3_panelA_full_precision.csv", row.names = FALSE)
saveRDS(fits_table3, "results/table3_models.rds")

# Compare only after estimation. The panel count is not the model sample size.
reference <- read.csv("reference/published_table3_panelA.csv")
comparison <- results %>%
  left_join(reference, by = c("specification", "outcome"), suffix = c("", "_paper")) %>%
  mutate(
    estimate_display = ifelse(grepl("^any_", outcome), sprintf("%.3f", estimate),
                              sprintf("%.0f", estimate)),
    se_display = ifelse(grepl("^any_", outcome), sprintf("%.3f", standard_error),
                       sprintf("%.0f", standard_error)),
    estimate_match = as.numeric(estimate_display) == estimate_paper,
    se_match = as.numeric(se_display) == standard_error_paper
  )
write.csv(comparison, "results/table3_panelA_comparison.csv", row.names = FALSE)
print(comparison %>% select(specification, outcome, estimate_display, se_display,
                           estimate_paper, standard_error_paper, estimate_match, se_match))
stopifnot(nrow(comparison) == 18, all(comparison$estimate_match), all(comparison$se_match))
capture.output(sessionInfo(), file = "results/table3_sessionInfo.txt")
cat("PASS: 18 estimates and 18 clustered SEs match Table 3 Panel A rows 1-3.\n")
