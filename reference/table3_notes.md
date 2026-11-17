# Table 3: scope and implementation

Source: Aron-Dine, Einav, and Finkelstein (2013), Table 3, p. 209, and the original `tables.do`, step 8 (lines 828 onward). Published values were transcribed from the article and visually checked against the PDF.

## Scope

Panel A compares 95% coinsurance with free care. This replication covers rows 1–3 and columns 1, 2, 4, 5, 6 and 7: any spending and dollar spending for total, inpatient and outpatient care. It does not reproduce log outcomes or the Lee bounds in row 4. All 18 coefficient estimates and 18 standard errors match after ordinary rounding to the published precision.

## Underreporting adjustment

The authors' code uses multipliers 1.04 for free care; 1.06 for the 25%, mixed and 50% plans; 1.14 for the 95% plan; and 1.11 for the individual-deductible plan. The R code preserves the original sequential operations:

1. Multiply outpatient spending by the plan multiplier.
2. Add the already-adjusted outpatient spending times `(multiplier - 1)` to total spending.
3. Multiply any-total-spending and any-outpatient-spending indicators by the same multiplier.
4. Leave inpatient outcomes unchanged at this stage.

Thus the total-spending update is `original_total + original_outpatient * multiplier * (multiplier - 1)`. It is not simply an addition of the original outpatient amount times the increment. This note documents fidelity to the supplied code; it does not assert that this particular sequencing is the only defensible correction.

Multiplying indicators produces adjusted pseudo-outcomes, some above one. These are the authors' correction procedure, not observed binary outcomes or individually recovered claims. Their contrasts can be discussed as corrected share differences under the adjustment assumptions.

## Additional baseline covariates

Row 3 adds the original list of pre-randomization variables: demographics, income, prior insurance, health, and prior utilization, including the supplied missingness indicators. Following the code, missing covariates are set to −1 and centered. The original list is retained in the R script. The fitted design has rank 87; redundant columns are handled by `lm()`.

## Sample and inference

All six plans and all 20,203 person-years enter the regressions; free care is the reference. The 10,564 shown in the paper's Panel A heading is 6,840 free-care plus 3,724 95%-plan observations. It is not the regression sample restriction. Models retain site-by-enrollment-month and enrollment-year indicators, with CR1 standard errors clustered on 3,209 family identifiers.

Validation independently reconstructs the cluster-score covariance for all 18 models, checks the baseline against Table 2, checks the sequential total-spending update against the original data, and verifies the panel count. No native Stata run was performed.

## Interpretation

The total-spending contrast changes from about −845 to −786 to −728 dollars. The final magnitude is about 14% smaller than the baseline. The adjusted any-total-spending contrast changes more, from −0.170 to −0.100 to −0.095. Both patterns remain negative, but magnitudes depend on reporting and specification assumptions. This exercise does not bound all possible selection bias or establish effects on health and welfare.

Article: https://doi.org/10.1257/jep.27.1.197

Authors' data/code: https://doi.org/10.3886/E113919V1
