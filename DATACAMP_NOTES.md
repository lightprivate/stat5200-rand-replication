# DataCamp course review and R function map

Reviewed through the signed-in Chrome DataCamp interface on November 16, 2026. Evidence consists of the Assignments page, seven course outlines showing completion, and two saved regression exercises. This is a course-level summary and selected exercise review, not an exhaustive export of every exercise or proof of mastery.

## Directly inspected courses

| Completed course | Verified coverage | Corresponding R syntax used or relevant here |
| --- | --- | --- |
| [Introduction to R](https://app.datacamp.com/learn/courses/free-introduction-to-r) | Variables, vectors, matrices, factors, data frames, lists | `<-`, indexing, `factor()`, `list()`, data frames |
| [Intermediate R](https://app.datacamp.com/learn/courses/intermediate-r) | Comparisons, logical operators, conditionals, loops, functions, apply family | `==`, `if`, `for`, `function`, `lapply()`, `sapply()`, `vapply()` |
| [Data Manipulation with dplyr](https://app.datacamp.com/learn/courses/data-manipulation-with-dplyr) | select/filter/arrange/mutate; count/group_by/summarize/ungroup; slice_min/max; rename | `%>%`, `select()`, `filter()`, `mutate()`, `count()`, `summarize()` |
| [Intermediate Regression in R](https://app.datacamp.com/learn/courses/intermediate-regression-in-r) | Numeric and categorical predictors; interactions; multiple linear and logistic regression; prediction | `lm(y ~ x1 + x2, data = d)`, categorical predictors, interaction formulas |
| [Inference for Linear Regression in R](https://app.datacamp.com/learn/courses/inference-for-linear-regression-in-r) | Simulation and t-based inference; intervals; conditions; multiple regression | Saved exercise visibly uses `lm(...) %>% tidy()` |
| [Hypothesis Testing in R](https://app.datacamp.com/learn/courses/hypothesis-testing-in-r) | t-tests, ANOVA, proportion tests, chi-square tests, nonparametric tests | Tests and p-values provide relevant background; no particular test function is claimed to have been verified in an exercise here |
| [Introduction to Data Visualization with ggplot2](https://app.datacamp.com/learn/courses/introduction-to-data-visualization-with-ggplot2) | Aesthetic mappings, scatter/bar/line geometries, themes | ggplot2 plotting concepts; not needed to estimate Table 2 |

The syntax column maps the reviewed topics to R code; it does not imply each listed function was individually inspected in a saved answer.

Two saved exercise editors were read in detail:

- Intermediate Regression → Multiple Linear Regression → Modeling 2 numeric explanatory variables: an explicit `lm()` formula with two predictors and `sqrt()`.
- Inference for Linear Regression → Building on Inference in Simple Linear Regression → Inference on coefficients: simple and multiple `lm()` formulas piped to `tidy()`.

## Other assignment statuses

The Assignments page also marked these courses completed: Exploratory Data Analysis in R, Sampling in R, A/B Testing in R, Machine Learning with Tree-Based Models in R, and Introduction to GitHub Concepts. Their individual code exercises were not audited in this review.

Analyzing Survey Data in R and Intermediate Data Visualization with ggplot2 were marked **LATE**, rather than COMPLETED. That status alone does not show how much material was studied; they are not used as evidence of completed knowledge here.

## How the replication now matches this style

1. Inspect samples and plan counts with `summarize()` and `count()`.
2. Create categorical controls with `mutate()` and `factor()`.
3. Show all six `lm()` formulas explicitly, instead of hiding the predictors behind `Y ~ .` and a generated design matrix.
4. Collect the models in a list and process them with an ordinary `for` loop.
5. Use `tidy()`, `filter()`, and `select()` to organize coefficients, then `bind_rows()` to combine outcomes.
6. Keep specialized statistical calculations and table formatting in separate, named files.

## Necessary additions beyond the verified exercises

- `foreign::read.dta()` reads the authors' Stata-format file; `write.csv()` saves outputs. Their appearance in completed coursework was not verified.
- `stopifnot()` performs automated checks; it is a convenience, not the regression method.
- `contr.treatment()` fixes the category coding so results do not depend on a session's contrast defaults.
- `sandwich::vcovCL()` supplies family-clustered standard errors. Ordinary `tidy(lm(...))` does not automatically reproduce these.
- The paper's free-care level averages over the sample's site/time mix. A factor-model intercept alone does not equal this reported level; the helper transforms both the estimate and its covariance.
- The joint test uses all five plan coefficients and their clustered covariance. Separate t-tests or the ordinary `summary(lm())` F statistic are not substitutes.
- The paper-style decimal formatting is a reporting step. The two-stage rounding reconstruction never changes the fitted estimates.

The main script uses familiar course patterns where practical. It does not claim that all methods required for this replication were covered in those courses.

## Sensitivity and presentation extension

`replicate_table3.R` keeps the same factors, explicit baseline formulas, ordinary loops, `lm()`, `tidy()`, `filter()`, `mutate()` and `bind_rows()` pattern. `reformulate()` is an additional utility for appending the authors' long baseline-covariate list; its coverage was not verified in a saved exercise.

`summarize_data.R` uses `summarize()`, `n_distinct()`, `count()`, `mutate()`, `mean()` and `median()`. `plot_results.R` uses `ggplot()`, `aes()`, points, segments, faceting and a simple theme. These follow the reviewed data-manipulation and visualization topics, but individual functions such as `geom_segment()`, `facet_wrap()` and `ggsave()` were not separately verified in saved answers. `qt()` constructs t-based intervals; family clustering remains a replication-specific addition.
