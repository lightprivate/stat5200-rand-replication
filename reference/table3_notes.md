# Table 3 notes

Source: the paper's Table 3 (p. 209) and the authors' `tables.do`, step 8 (from line 828). Published values were copied by hand from the paper and checked against the PDF.

## What is covered

Panel A: 95% coinsurance versus free care, rows 1 to 3. Columns 1, 2, 4, 5, 6 and 7, which are any spending and dollar spending for total, inpatient and outpatient care. Log outcomes and the bounds in row 4 are not covered.

All 18 estimates and 18 standard errors match the paper after normal rounding.

## Correction for missing claims (row 2)

The authors' code scales outcomes by a factor for each plan:

| Plan | Factor |
| --- | ---: |
| Free care | 1.04 |
| 25%, mixed, 50% | 1.06 |
| Individual deductible | 1.11 |
| 95% | 1.14 |

The steps run in this order, as in the authors' code:

1. Outpatient spending is multiplied by the factor.
2. Total spending gets the extra amount: the new outpatient spending times (factor − 1).
3. The any-total and any-outpatient indicators are multiplied by the factor.
4. Inpatient outcomes are left unchanged.

Because step 2 uses the already scaled outpatient amount, the new total is

$$\text{total} + \text{outpatient} \times f \times (f - 1)$$

where $f$ is the factor. I kept this order to match the code. It is not the only reasonable way to do the correction.

After step 3, the "any spending" indicators can be above 1. They are no longer yes/no outcomes. Their differences should be read as corrected shares, under the authors' assumptions.

## Pre-experiment controls (row 3)

Row 3 adds the authors' list of variables measured before the experiment: demographics, income, prior insurance, health, and prior care use, with their missing-value flags. As in the authors' code, missing values are set to −1 and the variables are centered. The model has rank 87. `lm()` drops the redundant columns.

## Sample and standard errors

The regressions use all six plans and all 20,203 person-years. Free care is the base. The 10,564 in the panel heading is 6,840 free-care plus 3,724 95%-plan observations; it does not restrict the sample. All models keep the site × enrollment month and enrollment year controls. Standard errors are clustered on the 3,209 families.

`validate_table3.R` checks the results a second way. It recomputes the clustered covariance by hand for all 18 models, checks row 1 against Table 2, checks the total-spending update against the data, and checks the panel count.

## Takeaway

Total spending: −845, then −786, then −728 dollars. The last is about 14% smaller than the first. Any total spending: −0.170, then −0.100, then −0.095. Both stay negative, but their size depends on the correction and the controls. These checks do not rule out all selection bias, and they say nothing about health outcomes.
