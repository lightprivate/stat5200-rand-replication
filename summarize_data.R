library(foreign)
library(dplyr)

d <- read.dta("data/person_years.dta", convert.factors = FALSE)
sample_summary <- d %>% summarize(
  person_years = n(), people = n_distinct(person),
  families = n_distinct(ifamily),
  mean_total = mean(spending_infl), median_total = median(spending_infl),
  share_positive_total = mean(any_spending),
  share_positive_inpatient = mean(any_inp),
  share_positive_outpatient = mean(any_out)
)
plan_counts <- d %>% count(rand_plan_group) %>% mutate(
  plan = c("Free care", "25%", "Mixed", "50%", "95%", "Individual deductible"),
  percent = 100 * n / sum(n)
)
write.csv(sample_summary, "results/sample_summary.csv", row.names = FALSE)
write.csv(plan_counts, "results/sample_by_plan.csv", row.names = FALSE)
print(sample_summary)
print(plan_counts)

