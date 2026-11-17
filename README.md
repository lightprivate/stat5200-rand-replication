# RAND Health Insurance Experiment: Replication in R

Private development and review repository. The final approved version will be published under `HongzhuoChen`; see [repository workflow](PUBLISHING.md).

This project reproduces the full Table 2 and selected sensitivity analyses from Table 3 in Aron-Dine, Einav, and Finkelstein (2013), *The RAND Health Insurance Experiment, Three Decades Later*, *Journal of Economic Perspectives*, 27(1), 197–222. The code follows the reviewed DataCamp style: explicit `lm()` formulas, factors, lists, `for` loops, and readable `dplyr` pipelines.

- [Article](https://doi.org/10.1257/jep.27.1.197)
- [Authors' public replication data](https://doi.org/10.3886/E113919V1)
- [Course review and function map](DATACAMP_NOTES.md)

## Run

Install these packages once:

```r
install.packages(c("foreign", "dplyr", "broom", "sandwich", "ggplot2"))
```

Set your working directory to this folder. Then use either:

```r
source("run_all.R")
```

or, in a terminal opened in this folder:

```sh
Rscript run_all.R
```

The scripts use relative paths deliberately, like a classroom R project. The working directory must be this folder. `run_all.R` runs the replication, sample summaries, figure exports, and numerical validation. Each component can also be run separately; run Table 2 before plotting or validation.

## Files

| File | Role |
| --- | --- |
| `replicate_table2.R` | Read/check data, fit six explicit regressions, organize results |
| `replicate_table3.R` | Table 3 Panel A, rows 1–3, six non-log outcomes |
| `summarize_data.R` | Person-year sample composition and spending summaries |
| `plot_results.R` | Coefficient and pointwise 95% confidence-interval plot |
| `run_all.R` | Run the complete workflow |
| `presentation_notes.txt` | Updated English speaker notes for the ten-slide presentation |
| `table2_inference.R` | Family clustering, adjusted free-care level, joint F tests |
| `export_results.R` | Compare all 78 entries with the paper and save results |
| `table_output.R` | Decimal formatting and CSV/PDF/LaTeX table layout |
| `validate_results.R` | Independent numerical check |
| `validate_table3.R` | Independent Table 3 covariance and adjustment checks |
| `DATACAMP_NOTES.md` | Observed course coverage and extra replication-specific methods |
| `data/`, `original/`, `reference/` | Authors' data/code and published reference values |
| `results/` | Generated estimates, tables, comparisons, and checks |

## Model and interpretation

The sample has 20,203 person-years for 5,915 individuals. All six models use OLS, including the three binary outcomes. Free care is plan 1 and the reference category. Models include site-by-start-month and enrollment-year indicators (`fam_start_year`, not the experiment-year index `year`). No extra filtering or weighting is applied.

The six formulas appear explicitly in the main script. The factor model's ordinary intercept refers to particular reference site/time categories. To reproduce the paper's free-care row, `table2_inference.R` instead averages the free-care fitted level over the sample's control distribution. This is algebraically equivalent to centering the control indicators in the original implementation. Its standard error uses the corresponding linear combination of the full covariance matrix.

`broom::tidy()` is used only for coefficient names and estimates. Its default standard errors and p-values are **not** used. The helper calculates `sandwich::vcovCL(..., type = "HC1", cadjust = TRUE)` clustered on `ifamily`, with 3,209 clusters. Joint tests use an F distribution with 5 and 3,208 degrees of freedom. These steps are necessary to preserve the paper's specification; they are additional to the DataCamp exercises reviewed.

## Results and display precision

The full-precision estimates are retained. Direct rounding matches 76 of 78 published numerical entries; the paper-style display matches all 78 using the same documented two-stage rounding rule:

- Inpatient spending SE for the 50% plan: 264.494993629 → 264.5 → 265.
- Inpatient spending joint p-value: 0.153863528 → 0.154 → 0.1540.

The final publication-rounding step is inferred from export-precision evidence, not verified editing history. No native Stata execution was performed. See `reference/evidence.txt` and the two-page result PDF.

## Targeted sensitivity analysis

`replicate_table3.R` reproduces **Panel A, rows 1–3, the six non-log columns**: the 95% coinsurance contrast with free care, under the baseline specification, after the authors' underreporting adjustment, and after additionally controlling for pre-randomization characteristics. All 18 estimates and 18 clustered standard errors match the published precision. See `results/table3_panelA_comparison.csv` and [implementation notes](reference/table3_notes.md).

| Specification | Any total spending | Total spending ($) | Inpatient spending ($) | Outpatient spending ($) |
| --- | ---: | ---: | ---: | ---: |
| Baseline | −0.170 | −845 | −217 | −629 |
| Underreporting adjustment | −0.100 | −786 | −217 | −582 |
| Adjustment + baseline covariates | −0.095 | −728 | −183 | −558 |

These are differences from free care, not group means. The main direction persists, while estimated magnitudes change. The adjustment uses plan-specific assumptions; it does not recover individually verified missing claims. Adjusted any-spending outcomes are scaled indicators and are no longer binary. The analysis therefore checks sensitivity to these assumptions rather than proving that all bias is removed.

The models use all 20,203 observations, following the authors' code. The panel heading's 10,564 is the combined count of the two highlighted plans, not a restriction imposed on the regressions.

The coefficient figure uses full-precision Table 2 estimates and family-clustered standard errors, with a t critical value on 3,208 degrees of freedom. Intervals are pointwise, not simultaneous; they do not replace the table's joint F tests. PNG, PDF and underlying CSV are in `results/`.

The large intermediate file `results/table3_models.rds` is regenerated by `replicate_table3.R` and excluded from the ZIP and Git tracking. Run that script before running `validate_table3.R` on its own. `run_all.R` handles the order automatically.

This version starts from the authors' cleaned data. It does not reproduce raw-data construction, Table 3's log outcomes, Panels B/C, Lee bounds, or income heterogeneity. Income interactions remain a proposed extension.

## Verification

The refactored implementation is checked against the saved pre-refactor results. See `results/comparison_before_datacamp_refactor.json` for coefficient, standard-error, joint-p-value, and display-table comparisons. The independent direct-covariance check is recorded in `results/independent_validation.csv`.
