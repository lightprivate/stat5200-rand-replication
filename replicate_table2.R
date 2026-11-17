# Run from this folder, or source the script in RStudio.
library(foreign)
library(dplyr)
library(broom)
library(sandwich)

root <- getwd()
out <- file.path(root, "results")
dir.create(out, showWarnings = FALSE)
source("table2_inference.R")
source("table_output.R")

# Read and inspect the data.
input <- file.path(root, "data", "person_years.dta")
d <- read.dta(input, convert.factors = FALSE)
outcomes <- c("any_spending", "spending_infl", "any_inp", "inp_infl",
              "any_out", "out_infl")
expected_counts <- c(6840, 2361, 1702, 1401, 3724, 4175)

sample_check <- d %>%
  summarize(person_years = n(), people = n_distinct(person),
            families = n_distinct(ifamily))
plan_counts <- d %>% count(rand_plan_group)
print(sample_check)
print(plan_counts)

stopifnot(nrow(d) == 20203, length(unique(d$person)) == 5915,
          all(plan_counts$n == expected_counts),
          !anyDuplicated(d[c("person", "year")]),
          !anyNA(d[c(outcomes, "rand_plan_group", "site", "fam_start_month",
                    "fam_start_year", "ifamily")]))
stopifnot(all(d$any_spending == (d$spending > 0)),
          all(d$any_inp == (d$inp > 0)), all(d$any_out == (d$out > 0)))

# Plan 1 is free care. Use enrollment year, not experiment-year index.
d <- d %>% mutate(
  plan = factor(rand_plan_group, levels = 1:6),
  site_month = factor(paste(site, fam_start_month, sep = "_")),
  start_year = factor(fam_start_year)
)
# Fix treatment coding even if the R session has different defaults.
contrasts(d$plan) <- contr.treatment(6, base = 1)
contrasts(d$site_month) <- contr.treatment(nlevels(d$site_month))
contrasts(d$start_year) <- contr.treatment(nlevels(d$start_year))

# Fit one model for each column of Table 2.
model_any_total <- lm(any_spending ~ plan + site_month + start_year, data = d)
model_total <- lm(spending_infl ~ plan + site_month + start_year, data = d)
model_any_inpatient <- lm(any_inp ~ plan + site_month + start_year, data = d)
model_inpatient <- lm(inp_infl ~ plan + site_month + start_year, data = d)
model_any_outpatient <- lm(any_out ~ plan + site_month + start_year, data = d)
model_outpatient <- lm(out_infl ~ plan + site_month + start_year, data = d)

fits <- list(any_spending = model_any_total, spending_infl = model_total,
             any_inp = model_any_inpatient, inp_infl = model_inpatient,
             any_out = model_any_outpatient, out_infl = model_outpatient)

# Keep tidy() estimates; replace its default inference with family clustering.
raw <- list()
models <- list()
summaries <- list()
N <- nrow(d)
G <- length(unique(d$ifamily))
for (y in names(fits)) {
  fit <- fits[[y]]
  inference <- table2_inference(fit, d$ifamily)
  result <- tidy(fit) %>%
    filter(term %in% c("(Intercept)", "plan2", "plan3", "plan4", "plan5", "plan6")) %>%
    select(term, estimate)

  # The paper's free-care row averages over the sample's location/time mix.
  result$estimate[1] <- inference$coefficients[1]
  result$standard_error <- sqrt(diag(inference$covariance))
  result$term <- names(inference$coefficients)
  result$outcome <- y
  raw[[y]] <- result[c(1, 2, 3, 4, 6, 5),
                    c("outcome", "term", "estimate", "standard_error")]
  models[[y]] <- inference
  summaries[[y]] <- data.frame(outcome = y, N = N, rank = fit$rank, clusters = G,
    joint_F = inference$F, numerator_df = 5, denominator_df = G - 1,
    joint_p = inference$p)
}
raw <- bind_rows(raw)
summaries <- bind_rows(summaries)
write.csv(raw, file.path(out, "full_precision.csv"), row.names = FALSE)
write.csv(summaries, file.path(out, "model_summary.csv"), row.names = FALSE)
saveRDS(models, file.path(out, "estimates_and_covariances.rds"))

# Compare the estimates with the paper and export CSV/PDF tables.
source("export_results.R")
