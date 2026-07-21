# Screenshot Sample Data

This file is the single source of fictional inputs and expected checks for store captures. Recalculate each result with the release candidate and independently verify it before approving artwork.

## 1. Home Dashboard

- Search: empty
- Locale: English primary; Turkish duplicate set optional
- Expected: hero, search field, category headings, and module cards; no empty state

## 2. Equation Solver

- Equation: `x^2 - 5x + 6 = 0`
- Expected roots: `x₁ = 2`, `x₂ = 3`
- Expected classification: successful analytic/quadratic result

## 3. Calculus

Preferred derivative capture:

- Function: `sin(x)`
- Point: `x = 1`
- Expected derivative: approximately `0.540302` (`cos(1)`)

Alternative integral capture:

- Function: `sin(x)`
- Bounds: `0` to `π`
- Expected integral: approximately `2`

Use the operation whose current result view presents the graph most clearly; retain its approximation/method label.

## 4. Statistics

- Dataset: `1, 2, 3, 4, 5, 8, 13`
- Count: `7`
- Mean: approximately `5.142857`
- Median: `4`
- Minimum/maximum: `1` / `13`
- Range: `12`

## 5. Financial Calculator

Preferred NPV capture:

- Initial cash flow: `-1000`
- Year 1: `600`
- Year 2: `600`
- Discount rate: `10%`
- Expected NPV: approximately `41.32`

All values are fictional. Keep educational/method wording visible and avoid account, investment, or recommendation language.

## 6. Operations Research — Assignment

Minimize this cost matrix:

```text
9  2  7
6  4  3
5  8  1
```

- Expected assignments: row 1 → column 2, row 2 → column 1, row 3 → column 3
- Expected total cost: `9`
- Expected method: Hungarian, if that is the method label produced by the current solver

## 7. CPM/PERT

| Activity | Duration | Predecessors |
| --- | ---: | --- |
| A | 3 | — |
| B | 4 | A |
| C | 2 | A |
| D | 3 | B, C |

- Expected critical path: `A → B → D`
- Expected project duration: `10`

## 8. Saved Calculations

- Save the Equation Solver, Statistics, and Assignment results above.
- Use generic titles only; no person, email, account, or institution name.
- Expected: at least three records, module filter, search, favorite, copy, and delete actions visible as the layout permits.
